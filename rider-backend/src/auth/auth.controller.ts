import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  async signup(
    @Body('name') name: string,
    @Body('email') email: string,
    @Body('password') password: string,
    @Body('phone') phone?: string,
    @Body('role') role: 'CUSTOMER' | 'DRIVER' = 'CUSTOMER',
    @Body('deviceInfo') deviceInfo?: { deviceId: string; deviceName?: string; ip?: string },
  ) {
    return this.authService.signup(name, email, password, phone, role, deviceInfo);
  }

  @Post('login')
  async login(
    @Body('email') email: string,
    @Body('password') password: string,
    @Body('deviceInfo') deviceInfo: { deviceId: string; deviceName?: string; ip?: string },
  ) {
    return this.authService.login(email, password, deviceInfo);
  }

  @Post('refresh')
  async refresh(@Body() body: RefreshTokenDto) {
    // ✅ TypeScript now knows refreshToken is a string
    return this.authService.refresh(body.refreshToken);
  }
}
