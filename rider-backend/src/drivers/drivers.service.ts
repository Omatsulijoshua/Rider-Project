import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DriverStatus } from '@prisma/client';

@Injectable()
export class DriversService {
  constructor(private prisma: PrismaService) {}

  async updateLocation(userId: string, lat: number, lng: number) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
    });

    if (!driver) throw new NotFoundException('Driver not found');

    return this.prisma.driver.update({
      where: { userId },
      data: {
        latitude: lat,
        longitude: lng,
      },
    });
  }

  async getDriverByUserId(userId: string) {
    return this.prisma.driver.findUnique({
      where: { userId },
      include: { user: true },
    });
  }

  async updateStatus(userId: string, isOnline: boolean) {
    const status = isOnline ? DriverStatus.AVAILABLE : DriverStatus.OFFLINE;
    console.log(`🔄 Updating driver status for ${userId}: isOnline=${isOnline}, status=${status}`);
    
    return this.prisma.driver.upsert({
      where: { userId },
      update: { 
        isOnline,
        status
      },
      create: {
        userId,
        isOnline,
        status
      }
    });
  }
}
