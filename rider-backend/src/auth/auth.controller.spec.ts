// auth.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { UnauthorizedException } from '@nestjs/common';

describe('AuthController', () => {
  let controller: AuthController;

  // Mock JwtService
  const mockJwtService = {
    sign: jest.fn(),
  };

  // Mock PrismaService
  const mockPrismaService = {
    refreshToken: {
      findUnique: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        { provide: JwtService, useValue: mockJwtService },
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should return access token for valid refresh token', async () => {
    mockPrismaService.refreshToken.findUnique.mockResolvedValue({
      token: 'valid_token',
      revoked: false,
      expiresAt: new Date(Date.now() + 10000), // 10 seconds in the future
      userId: 'user123',
    });

    mockPrismaService.user.findUnique.mockResolvedValue({
      id: 'user123',
      role: 'CUSTOMER',
    });

    mockJwtService.sign.mockReturnValue('access_token');

    const result = await controller.refresh({ refreshToken: 'valid_token' });

    expect(result).toEqual({ accessToken: 'access_token' });
    expect(mockPrismaService.refreshToken.findUnique).toHaveBeenCalledWith({
      where: { token: 'valid_token' },
    });
    expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
      where: { id: 'user123' },
    });
  });

  it('should throw UnauthorizedException for invalid token', async () => {
    mockPrismaService.refreshToken.findUnique.mockResolvedValue(null);

    await expect(
      controller.refresh({ refreshToken: 'invalid_token' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('should throw UnauthorizedException for expired token', async () => {
    mockPrismaService.refreshToken.findUnique.mockResolvedValue({
      token: 'expired_token',
      revoked: false,
      expiresAt: new Date(Date.now() - 10000), // 10 seconds in the past
      userId: 'user123',
    });

    await expect(
      controller.refresh({ refreshToken: 'expired_token' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('should throw UnauthorizedException for revoked token', async () => {
    mockPrismaService.refreshToken.findUnique.mockResolvedValue({
      token: 'revoked_token',
      revoked: true,
      expiresAt: new Date(Date.now() + 10000),
      userId: 'user123',
    });

    await expect(
      controller.refresh({ refreshToken: 'revoked_token' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
