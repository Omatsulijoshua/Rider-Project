import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-custom';
import { PrismaService } from '../prisma/prisma.service';

/**
 * This strategy validates a refresh token.
 * You can use it with @UseGuards(RefreshTokenGuard)
 * to protect refresh token endpoints.
 */
@Injectable()
export class RefreshTokenStrategy extends PassportStrategy(Strategy, 'refresh') {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  /**
   * Validate the refresh token
   * @param req Express request, body must contain { refreshToken }
   */
  async validate(req: any) {
    const refreshToken = req.body.refreshToken;

    if (!refreshToken) {
      throw new UnauthorizedException('Refresh token not provided');
    }

    // Find token in database
    const tokenRecord = await this.prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!tokenRecord || tokenRecord.revoked || tokenRecord.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Return user info to attach to request.user
    return {
      userId: tokenRecord.user.id,
      role: tokenRecord.user.role,
      tokenId: tokenRecord.id,
    };
  }
}
