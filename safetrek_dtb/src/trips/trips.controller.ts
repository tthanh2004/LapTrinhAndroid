import { Controller, Post, Body, Patch, Param } from '@nestjs/common';
import { TripsService } from './trips.service';
import * as bcrypt from 'bcrypt'; // Dùng để test tạo mã hash

@Controller('trips')
export class TripsController {
  constructor(private readonly tripService: TripsService) {}

  // 1. API Bắt đầu chuyến đi
  @Post('start')
  async startTrip(
    @Body()
    body: {
      userId: number;
      durationMinutes: number;
      destinationName?: string;
    },
  ) {
    return this.tripService.startTrip(
      body.userId,
      body.durationMinutes,
      body.destinationName,
    );
  }

  // 2. API Kết thúc chuyến đi
  @Patch(':id/end')
  async endTrip(@Body() body: { status: string }, @Param('id') id: string) {
    // status: 'COMPLETED_SAFE' hoặc 'DURESS_ENDED'
    return this.tripService.endTripSafe(Number(id), body.status);
  }

  // 3. API Panic (Nút Hoảng loạn)
  @Post('panic')
  async sendPanic(@Body() body: { userId: number; tripId?: number }) {
    return this.tripService.sendPanicAlert(body.userId, body.tripId);
  }

  // 4. API Xác thực mã PIN (Logic quan trọng nhất)
  @Post('verify-pin')
  async verifyPin(@Body() body: { userId: number; pin: string }) {
    return this.tripService.verifyPin(body.userId, body.pin);
  }

  // 5. API Tiện ích: Tạo mã Hash (Để bạn lấy chuỗi này nhét vào DB)
  @Post('hash-test')
  async hashTest(@Body() body: { pin: string }) {
    const salt = await bcrypt.genSalt();
    const hash = await bcrypt.hash(body.pin, salt);
    return { original: body.pin, hash: hash };
  }
}
