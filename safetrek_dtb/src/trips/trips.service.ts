import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as bcrypt from 'bcrypt';
import { TripStatus } from '@prisma/client';

@Injectable()
export class TripsService {
  constructor(private prisma: PrismaService) {}

  async startTrip(userId: number, duration: number, dest?: string) {
    try {
      // 1. Kiểm tra User tồn tại
      const userExists = await this.prisma.user.findUnique({
        where: { userId },
      });
      if (!userExists) {
        throw new NotFoundException(`User ID ${userId} không tồn tại.`);
      }

      // 2. Tạo Trip
      const trip = await this.prisma.trip.create({
        data: {
          userId: userId,
          durationMinutes: duration,
          destinationName: dest,
          expectedEndTime: new Date(new Date().getTime() + duration * 60000),
          status: TripStatus.ACTIVE,
        },
      });
      return { message: 'Trip started', tripId: trip.tripId };
    } catch (error) {
      // [FIX LỖI ESLINT] Ép kiểu error thành Error
      if (error instanceof NotFoundException) throw error;

      const err = error as Error;
      throw new InternalServerErrorException(
        `Lỗi tạo trip: ${err.message || 'Unknown error'}`,
      );
    }
  }

  async endTripSafe(tripId: number, statusString: string = 'COMPLETED_SAFE') {
    const status =
      TripStatus[statusString as keyof typeof TripStatus] ||
      TripStatus.COMPLETED_SAFE;
    await this.prisma.trip.update({
      where: { tripId: tripId },
      data: { status: status },
    });
    return { message: 'Trip ended', status: status };
  }

  async verifyPin(userId: number, inputPin: string) {
    const user = await this.prisma.user.findUnique({ where: { userId } });
    if (!user) return { status: 'ERROR', message: 'User not found' };

    if (user.safePinHash) {
      const isSafe = await bcrypt.compare(inputPin, user.safePinHash);
      if (isSafe) return { status: 'SAFE', message: 'Safe PIN correct' };
    }

    if (user.duressPinHash) {
      const isDuress = await bcrypt.compare(inputPin, user.duressPinHash);
      if (isDuress)
        return { status: 'DURESS', message: 'Duress PIN triggered' };
    }

    return { status: 'INVALID', message: 'Incorrect PIN' };
  }
}
