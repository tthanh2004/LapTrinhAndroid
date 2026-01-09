import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  ParseIntPipe,
} from '@nestjs/common';
import { EmergencyService } from './emergency.service';
import { GuardianStatus } from '@prisma/client';

@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergencyService: EmergencyService) {}

  // 1. Lấy danh sách người bảo vệ
  @Get('guardians/:userId')
  async getGuardians(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getGuardians(userId);
  }

  // 2. Thêm người bảo vệ (Gửi lời mời)
  @Post('guardians')
  async addGuardian(
    @Body() body: { userId: number; name: string; phone: string },
  ) {
    return this.emergencyService.addGuardian(
      body.userId,
      body.name,
      body.phone,
    );
  }

  // 3. Xóa người bảo vệ
  @Delete('guardians/:id')
  async deleteGuardian(@Param('id', ParseIntPipe) id: number) {
    return this.emergencyService.deleteGuardian(id);
  }

  // 4. API Phản hồi (Chấp nhận/Từ chối lời mời)
  @Post('guardians/respond')
  async respondToRequest(
    @Body() body: { guardianId: number; status: 'ACCEPTED' | 'REJECTED' },
  ) {
    const statusEnum =
      body.status === 'ACCEPTED'
        ? GuardianStatus.ACCEPTED
        : GuardianStatus.REJECTED;
    return this.emergencyService.respondToGuardianRequest(
      body.guardianId,
      statusEnum,
    );
  }

  // ==========================================================
  // 5. API Kích hoạt Panic (ĐÃ CẬP NHẬT THÊM tripId)
  // ==========================================================
  @Post('panic')
  async triggerPanic(
    @Body()
    body: {
      userId: number;
      lat: number;
      lng: number;
      tripId?: number;
      batteryLevel?: number; // [QUAN TRỌNG] Thêm dòng này để nhận mức pin
    },
  ) {
    return this.emergencyService.triggerPanicAlert(
      body.userId,
      body.lat,
      body.lng,
      body.tripId,
      body.batteryLevel, // Truyền sang service
    );
  }
  // ==========================================================

  // 6. Lấy danh sách thông báo
  @Get('notifications/:userId')
  async getNotifications(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getUserNotifications(userId);
  }

  // 7. Lấy danh sách người tôi đang bảo vệ
  @Get('protecting/:userId')
  async getPeopleIProtect(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getPeopleIProtect(userId);
  }

  // 8. API Đếm thông báo chưa đọc
  @Get('notifications/unread/:userId')
  async getUnreadCount(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getUnreadCount(userId);
  }

  // 9. API Đánh dấu tất cả đã đọc
  @Post('notifications/read-all')
  async markAllRead(@Body() body: { userId: number }) {
    return this.emergencyService.markAllAsRead(body.userId);
  }

  @Post('notifications/send')
  async sendNotification(
    @Body() body: { userId: number; title: string; body: string },
  ) {
    return this.emergencyService.sendManualNotification(
      body.userId,
      body.title,
      body.body,
    );
  }
}
