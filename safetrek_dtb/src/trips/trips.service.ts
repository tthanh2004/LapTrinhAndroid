import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as bcrypt from 'bcrypt';
import { TripStatus } from '@prisma/client'; // <--- 1. Import Enum từ Prisma

@Injectable()
export class TripsService {
  constructor(private prisma: PrismaService) {}

  // 1. Logic Bắt đầu
  async startTrip(userId: number, duration: number, dest?: string) {
    try {
      // Log dữ liệu đầu vào để kiểm tra
      console.log('--- START TRIP REQUEST ---');
      console.log('UserID:', userId, typeof userId);
      console.log('Duration:', duration, typeof duration);

      const trip = await this.prisma.trip.create({
        data: {
          userId: userId, // Kiểm tra xem userId này có tồn tại trong bảng User chưa?
          durationMinutes: duration,
          destinationName: dest,
          expectedEndTime: new Date(new Date().getTime() + duration * 60000),
          status: TripStatus.ACTIVE,
        },
      });

      console.log('✅ Trip Created:', trip.tripId);
      return { message: 'Trip started', tripId: trip.tripId };
    } catch (error) {
      // In lỗi chi tiết ra Terminal của Backend
      console.error('❌ LỖI KHI TẠO TRIP:', error);

      // Ném lỗi ra để Postman/Flutter thấy
      throw new InternalServerErrorException(
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        `Lỗi tạo chuyến đi: ${error.message}`,
      );
    }
  }

  // 2. Logic Kết thúc (Đã sửa chuẩn)
  async endTripSafe(tripId: number, statusString: string = 'COMPLETED_SAFE') {
    // 3. Kiểm tra xem status gửi lên có hợp lệ không
    // Nếu statusString không nằm trong Enum, nó sẽ lấy mặc định là COMPLETED_SAFE
    const status =
      TripStatus[statusString as keyof typeof TripStatus] ||
      TripStatus.COMPLETED_SAFE;

    await this.prisma.trip.update({
      where: { tripId: tripId },
      data: { status: status }, // <--- Không cần 'as any' nữa
    });
    return { message: 'Trip ended', status: status };
  }

  // 3. Logic Panic
  async sendPanicAlert(userId: number, tripId?: number) {
    await this.prisma.alert.create({
      data: {
        userId: userId,
        tripId: tripId,
        alertType: 'PANIC_BUTTON',
      },
    });
    console.log(`🚨 PANIC ALERT received for User ${userId}`);
    return { message: 'Alert sent' };
  }

  // 4. Logic Check PIN
  async verifyPin(userId: number, inputPin: string) {
    const user = await this.prisma.user.findUnique({
      where: { userId: userId },
    });

    if (!user) return { status: 'ERROR', message: 'User not found' };

    // A. Check Safe PIN
    if (user.safePinHash) {
      const isSafe = await bcrypt.compare(inputPin, user.safePinHash);
      if (isSafe) return { status: 'SAFE', message: 'Safe PIN correct' };
    }

    // B. Check Duress PIN
    if (user.duressPinHash) {
      const isDuress = await bcrypt.compare(inputPin, user.duressPinHash);
      if (isDuress)
        return { status: 'DURESS', message: 'Duress PIN triggered' };
    }

    return { status: 'INVALID', message: 'Incorrect PIN' };
  }
}
