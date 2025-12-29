import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // 1. Đăng ký (Tạo user với mật khẩu hash)
  @Post('register')
  async register(
    @Body()
    body: {
      phoneNumber: string;
      password: string;
      fullName: string;
      email?: string;
    },
  ) {
    return this.authService.register(body);
  }

  // 2. Đăng nhập bằng Mật khẩu
  @Post('login-password')
  async loginPassword(@Body() body: { identity: string; password: string }) {
    return this.authService.loginWithPassword(body.identity, body.password);
  }

  // ... (Giữ nguyên các API cũ: check-login-method, login-firebase, send-otp, verify-otp)
  @Post('check-login-method')
  async checkLoginMethod(@Body('phoneNumber') phoneNumber: string) {
    return this.authService.checkLoginMethod(phoneNumber);
  }

  @Post('login-firebase')
  async loginFirebase(@Body('token') token: string) {
    return this.authService.loginWithFirebase(token);
  }

  @Post('send-otp')
  async sendOtp(@Body('email') email: string) {
    return this.authService.sendEmailOtp(email);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { email: string; code: string }) {
    return this.authService.verifyEmailOtp(body.email, body.code);
  }
}
