import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(
    @Body()
    body: {
      phoneNumber: string;
      passwordHash: string; // [ĐÃ KHỚP]
      fullName: string;
      email?: string;
      safePinHash: string; // [ĐÃ KHỚP]
      duressPinHash: string; // [ĐÃ KHỚP]
    },
  ) {
    return this.authService.register(body);
  }

  @Post('verify-safe-pin')
  async verifySafePin(@Body() body: { userId: number; pin: string }) {
    return this.authService.verifySafePin(body.userId, body.pin);
  }

  @Post('login')
  async login(@Body() body: { identity: string; password: string }) {
    return this.authService.loginWithPassword(body.identity, body.password);
  }
}
