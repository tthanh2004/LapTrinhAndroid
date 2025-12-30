import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // 1. Đăng ký gộp
  @Post('register')
  async register(
    @Body()
    body: {
      phoneNumber: string;
      password: string;
      fullName: string;
      email?: string;
      safePin: string; // [SỬA] App gửi 'safePin' (1234), không phải hash
      duressPin: string; // [SỬA] App gửi 'duressPin' (9999)
    },
  ) {
    return this.authService.register(body);
  }

  // 2. Xác thực PIN an toàn
  @Post('verify-safe-pin')
  async verifySafePin(@Body() body: { userId: number; pin: string }) {
    return this.authService.verifySafePin(body.userId, body.pin);
  }

  // 3. Đăng nhập
  @Post('login')
  async login(@Body() body: { identity: string; password: string }) {
    return this.authService.loginWithPassword(body.identity, body.password);
  }
}
