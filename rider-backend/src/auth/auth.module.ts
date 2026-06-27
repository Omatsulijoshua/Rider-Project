import { Module } from '@nestjs/common';
import { JwtModule, JwtModuleOptions } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { PrismaModule } from '../prisma/prisma.module';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (
        config: ConfigService,
      ): Promise<JwtModuleOptions> => {
        // ✅ Read config with fallback
        const secret = config.get<string>('JWT_SECRET') || 'default_secret';
        const expiresIn = config.get<string>('JWT_EXPIRES_IN') || '15m';

        return {
          secret,
          signOptions: {
            // ✅ cast as string | number to satisfy TypeScript
            expiresIn: expiresIn as string | number,
          },
        } as JwtModuleOptions;
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
