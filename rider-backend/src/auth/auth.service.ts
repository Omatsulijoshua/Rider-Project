import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import { addDays } from 'date-fns';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
  ) {}

  async signup(
    name: string,
    email: string,
    password: string,
    phone?: string, // ✅ make optional
    role: 'CUSTOMER' | 'DRIVER' = 'CUSTOMER',
    deviceInfo?: { deviceId: string; deviceName?: string; ip?: string },
  ) {
    // ✅ Check email
    const existingEmail = await this.prisma.user.findUnique({
      where: { email },
    });
    if (existingEmail) {
      throw new ForbiddenException('User already exists');
    }

    // ✅ Check phone ONLY if provided
    if (phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone },
      });
      if (existingPhone) {
        throw new ForbiddenException('Phone already exists');
      }
    }

    // 🔐 Hash password
    const passwordHash = await bcrypt.hash(password, 10);

   try {
      const user = await this.prisma.user.create({
        data: {
          email,
          name,
          phone: phone!,
          passwordHash,
          role,
          status: 'ACTIVE',
        },
      });

      // 🏎️ Create Driver record if role is DRIVER
      if (role === 'DRIVER') {
        await this.prisma.driver.upsert({
          where: { userId: user.id },
          update: {},
          create: {
            userId: user.id,
            status: 'OFFLINE',
            isOnline: false,
          },
        });
      }

      // 📱 Device binding
      if (deviceInfo) {
        await this.prisma.userDevice.upsert({
          where: {
            userId_deviceId: {
              userId: user.id,
              deviceId: deviceInfo.deviceId,
            },
          },
          update: {
            lastLogin: new Date(),
            lastIp: deviceInfo.ip,
          },
          create: {
            userId: user.id,
            deviceId: deviceInfo.deviceId,
            deviceName: deviceInfo.deviceName,
            lastIp: deviceInfo.ip,
          },
        });
      }

      // 🔑 Access token
      const accessToken = this.jwt.sign(
        { role: user.role },
        { subject: user.id, expiresIn: '15m' },
      );

      // 🔄 Refresh token
      const refreshToken = randomUUID();
      await this.prisma.refreshToken.create({
        data: {
          userId: user.id,
          token: refreshToken,
          expiresAt: addDays(new Date(), 30),
        },
      });

      return {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
      };
    }catch (error: any) {
  if (error.code === 'P2002') {
    throw new ForbiddenException('User already exists');
  }
  throw error;
}
  }

  async login(
    email: string,
    password: string,
    deviceInfo: { deviceId: string; deviceName?: string; ip?: string },
  ) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.status !== 'ACTIVE') {
      throw new ForbiddenException('Account not active');
    }

    // 🔐 Compare password
    const valid = await bcrypt.compare(password, user.passwordHash);

    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // 🏎️ Ensure Driver record exists if role is DRIVER
    if (user.role === 'DRIVER') {
      await this.prisma.driver.upsert({
        where: { userId: user.id },
        update: {},
        create: {
          userId: user.id,
          status: 'OFFLINE',
          isOnline: false,
        },
      });
    }

    // 📱 Device binding
    await this.prisma.userDevice.upsert({
      where: {
        userId_deviceId: {
          userId: user.id,
          deviceId: deviceInfo.deviceId,
        },
      },
      update: {
        lastLogin: new Date(),
        lastIp: deviceInfo.ip,
      },
      create: {
        userId: user.id,
        deviceId: deviceInfo.deviceId,
        deviceName: deviceInfo.deviceName,
        lastIp: deviceInfo.ip,
      },
    });

    // 🔑 Access token
    const accessToken = this.jwt.sign(
      { role: user.role },
      { subject: user.id, expiresIn: '15m' },
    );

    // 🔄 Refresh token
    const refreshToken = randomUUID();
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt: addDays(new Date(), 30),
      },
    });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    };
  }

  async refresh(refreshToken: string) {
    const tokenRecord = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
    });

    if (!tokenRecord || tokenRecord.revoked) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (tokenRecord.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token expired');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: tokenRecord.userId },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    if (user.status !== 'ACTIVE') {
      throw new ForbiddenException('Account not active');
    }

    const accessToken = this.jwt.sign(
      { role: user.role },
      { subject: user.id, expiresIn: '15m' },
    );

    return { accessToken };
  }
}