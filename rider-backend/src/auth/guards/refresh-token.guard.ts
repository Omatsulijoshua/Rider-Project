import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Guard to protect routes that require a valid refresh token.
 * Uses the 'refresh' strategy defined in RefreshTokenStrategy.
 */
@Injectable()
export class RefreshTokenGuard extends AuthGuard('refresh') {}
