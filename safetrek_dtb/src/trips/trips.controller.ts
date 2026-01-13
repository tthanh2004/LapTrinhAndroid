import { Controller, Post, Body, Patch, Param } from '@nestjs/common';
import { TripsService } from './trips.service';
import * as bcrypt from 'bcrypt';

@Controller('trips')
export class TripsController {
  constructor(private readonly tripService: TripsService) {}

  // Bắt đầu chuyến đi -> POST (Tạo mới trip)
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

  // Kết thúc chuyến đi (Cập nhật trạng thái) -> PATCH (Chuẩn)
  @Patch(':id/end')
  async endTrip(@Body() body: { status: string }, @Param('id') id: string) {
    return this.tripService.endTripSafe(Number(id), body.status);
  }

  // Xác thực PIN -> POST (Ngoại lệ bảo mật)
  @Post('verify-pin')
  async verifyPin(@Body() body: { userId: number; pin: string }) {
    return this.tripService.verifyPin(body.userId, body.pin);
  }

  // Test Hash -> POST (Utility)
  @Post('hash-test')
  async hashTest(@Body() body: { pin: string }) {
    const salt = await bcrypt.genSalt();
    const hash = await bcrypt.hash(body.pin, salt);
    return { original: body.pin, hash: hash };
  }
}
