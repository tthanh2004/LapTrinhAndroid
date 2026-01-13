import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  ParseIntPipe,
  Patch, // Import thêm Patch
} from '@nestjs/common';
import { EmergencyService } from './emergency.service';
import { GuardianStatus } from '@prisma/client';

@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergencyService: EmergencyService) {}

  // 1. Lấy danh sách -> GET
  @Get('guardians/:userId')
  async getGuardians(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getGuardians(userId);
  }

  // 2. Gửi lời mời (Tạo mới quan hệ) -> POST
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

  // 3. Xóa người bảo vệ -> DELETE
  @Delete('guardians/:id')
  async deleteGuardian(@Param('id', ParseIntPipe) id: number) {
    return this.emergencyService.deleteGuardian(id);
  }

  // 4. [SỬA LỚN] Phản hồi lời mời -> PATCH
  // URL: /emergency/guardians/:id/respond
  // ID của guardian nằm trên URL, Status nằm trong Body
  @Patch('guardians/:id/respond')
  async respondToRequest(
    @Param('id', ParseIntPipe) guardianId: number,
    @Body() body: { status: 'ACCEPTED' | 'REJECTED' },
  ) {
    const statusEnum =
      body.status === 'ACCEPTED'
        ? GuardianStatus.ACCEPTED
        : GuardianStatus.REJECTED;

    return this.emergencyService.respondToGuardianRequest(
      guardianId,
      statusEnum,
    );
  }

  // 5. Kích hoạt Panic -> POST (Tạo ra 1 sự kiện panic)
  @Post('panic')
  async triggerPanic(
    @Body()
    body: {
      userId: number;
      lat: number;
      lng: number;
      tripId?: number;
      batteryLevel?: number;
    },
  ) {
    return this.emergencyService.triggerPanicAlert(
      body.userId,
      body.lat,
      body.lng,
      body.tripId,
      body.batteryLevel,
    );
  }

  // 6. Lấy thông báo -> GET
  @Get('notifications/:userId')
  async getNotifications(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getUserNotifications(userId);
  }

  // 7. Lấy danh sách người tôi bảo vệ -> GET
  @Get('protecting/:userId')
  async getPeopleIProtect(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getPeopleIProtect(userId);
  }

  // 8. Đếm chưa đọc -> GET
  @Get('notifications/unread/:userId')
  async getUnreadCount(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getUnreadCount(userId);
  }

  // 9. [SỬA] Đánh dấu đã đọc (Update status) -> PATCH
  @Patch('notifications/read-all')
  async markAllRead(@Body() body: { userId: number }) {
    return this.emergencyService.markAllAsRead(body.userId);
  }

  // 10. Gửi thông báo thủ công -> POST
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
