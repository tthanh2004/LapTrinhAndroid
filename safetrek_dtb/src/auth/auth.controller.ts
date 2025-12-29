import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // 1. API Check xem nên dùng Email hay SMS
  @Post('check-login-method')
  async checkLoginMethod(@Body('phoneNumber') phoneNumber: string) {
    return this.authService.checkLoginMethod(phoneNumber);
  }

  // 2. API Đăng nhập bằng Token Firebase (Khi dùng SMS)
  @Post('login-firebase')
  async loginFirebase(@Body('token') token: string) {
    return this.authService.loginWithFirebase(token);
  }

  // 3. API Gửi OTP Email (Cho trường hợp login bằng Gmail trực tiếp)
  @Post('send-otp')
  async sendOtp(@Body('email') email: string) {
    return this.authService.sendEmailOtp(email);
  }

  // 4. API Xác thực OTP Email
  @Post('verify-otp')
  async verifyOtp(@Body() body: { email: string; code: string }) {
    return this.authService.verifyEmailOtp(body.email, body.code);
  }
}
