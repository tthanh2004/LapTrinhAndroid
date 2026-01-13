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

  // Đăng ký - Tạo mới resource -> POST (Chuẩn)
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

  // Đăng nhập -> POST (Chuẩn)
  @Post('login')
  async login(@Body() body: { identity: string; password: string }) {
    return this.authService.loginWithPassword(body.identity, body.password);
  }

  // Lấy Profile -> GET (Chuẩn)
  @Get('profile/:id')
  async getProfile(@Param('id', ParseIntPipe) id: number) {
    return this.authService.getUserProfile(id);
  }

  // Cập nhật thông tin -> PATCH (Chuẩn)
  @Patch('profile/:id')
  async updateProfile(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { fullName?: string; email?: string },
  ) {
    return this.authService.updateProfile(id, body);
  }

  // Cập nhật FCM Token -> PATCH (Chuẩn)
  @Patch('fcm-token')
  async updateFcmToken(@Body() body: { userId: number; token: string }) {
    return this.authService.updateFcmToken(body.userId, body.token);
  }

  // [SỬA] Đổi mã PIN là hành động cập nhật -> Dùng PATCH
  // URL đổi thành 'pins' cho ngắn gọn
  @Patch('pins')
  async updatePins(
    @Body() body: { userId: number; safePin: string; duressPin: string },
  ) {
    return this.authService.updatePins(
      body.userId,
      body.safePin,
      body.duressPin,
    );
  }

  // Xác thực PIN -> POST (Ngoại lệ bảo mật, chấp nhận được)
  @Post('verify-safe-pin')
  async verifySafePin(@Body() body: { userId: number; pin: string }) {
    return this.authService.verifySafePin(body.userId, body.pin);
  }
}
