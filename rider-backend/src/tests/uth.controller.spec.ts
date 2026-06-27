import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from '../auth/auth.controller';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: AuthService;

  // ✅ Mock services
  const mockJwtService = {
    sign: jest.fn(),
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
    },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    userDevice: {
      upsert: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
    authService = module.get<AuthService>(AuthService);
  });

  // ✅ Basic existence test
  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  // ===============================
  // LOGIN TEST (via AuthService)
  // ===============================
  it('should return access and refresh token on login', async () => {
    // Mock user record
    mockPrismaService.user.findUnique.mockResolvedValue({
      id: 'user123',
      phone: '08012345678',
      password: '$2b$10$hashedpassword', // bcrypt hash
      role: 'CUSTOMER',
      isActive: true,
    });

    // Mock bcrypt comparison
    const bcrypt = require('bcrypt');
    jest.spyOn(bcrypt, 'compare').mockResolvedValue(true);

    // Mock userDevice upsert and refreshToken create
    mockPrismaService.userDevice.upsert.mockResolvedValue({});
    mockPrismaService.refreshToken.create.mockResolvedValue({});

    // Mock JWT
    mockJwtService.sign.mockReturnValue('access_token');

    const result = await authService.login('08012345678', 'password123', {
      deviceId: 'device001',
      deviceName: 'iPhone',
      ip: '127.0.0.1',
    });

    expect(result).toHaveProperty('accessToken', 'access_token');
    expect(result).toHaveProperty('refreshToken');
  });

  // ===============================
  // REFRESH TOKEN TEST
  // ===============================
  it('should return new access token on valid refresh token', async () => {
    // Mock refresh token lookup
    mockPrismaService.refreshToken.findUnique.mockResolvedValue({
      token: 'validtoken',
      revoked: false,
      expiresAt: new Date(Date.now() + 10000),
      userId: 'user123',
      user: { id: 'user123', role: 'CUSTOMER' },
    });

    // Mock JWT
    mockJwtService.sign.mockReturnValue('new_access_token');

    // Call controller refresh manually
    const result = await controller.refresh({ refreshToken: 'validtoken' });

    expect(result).toEqual({ accessToken: 'new_access_token' });
  });

  it('should throw UnauthorizedException for invalid refresh token', async () => {
    mockPrismaService.refreshToken.findUnique.mockResolvedValue(null);

    await expect(controller.refresh({ refreshToken: 'invalidtoken' })).rejects.toThrow(
      UnauthorizedException,
    );
  });
});
