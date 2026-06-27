import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy, StrategyOptions } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

// Define JWT payload type
interface JwtPayload {
  sub: string; // userId
  role: 'CUSTOMER' | 'DRIVER' | 'ADMIN';
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(private readonly config: ConfigService) {
    // Define options with correct types
    const options: StrategyOptions = {
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('JWT_SECRET')!, // ✅ use non-null assertion
    };
    super(options);
  }

  async validate(payload: JwtPayload) {
    // Attach user info to request
    return {
      userId: payload.sub,
      role: payload.role,
    };
  }
}
