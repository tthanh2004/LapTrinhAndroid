import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  ParseIntPipe,
  Patch,
} from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(
    @Body()
    body: {
      phoneNumber: string;
      passwordHash: string;
      fullName: string;
      email?: string;
      safePinHash: string;
      duressPinHash: string;
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

  // [MỚI] Lấy thông tin User (Profile)
  @Get('profile/:id')
  async getProfile(@Param('id', ParseIntPipe) id: number) {
    return this.authService.getUserProfile(id);
  }

  // [MỚI] Cập nhật FCM Token
  @Patch('fcm-token')
  async updateFcmToken(@Body() body: { userId: number; token: string }) {
    return this.authService.updateFcmToken(body.userId, body.token);
  }
}
