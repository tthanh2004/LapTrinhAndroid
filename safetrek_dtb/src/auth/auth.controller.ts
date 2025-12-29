import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Endpoint: POST /auth/login-firebase
   * Body: { "token": "chuỗi-token-từ-flutter" }
   */
  @Post('login-firebase')
  async loginFirebase(@Body() body: { token: string }) {
    return this.authService.loginWithFirebase(body.token);
  }

  @Post('send-email-otp')
  async sendEmailOtp(@Body() body: { email: string }) {
    return this.authService.sendEmailOtp(body.email);
  }

  @Post('verify-email-otp')
  async verifyEmailOtp(@Body() body: { email: string; code: string }) {
    return this.authService.verifyEmailOtp(body.email, body.code);
  }
}
