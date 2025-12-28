import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateTripDto } from './dto/create-trip.dto'; // <--- Import cái DTO vừa tạo

@Injectable()
export class TripsService {
  constructor(private prisma: PrismaService) {}

  // Thay 'data: any' bằng 'createTripDto: CreateTripDto'
  async create(createTripDto: CreateTripDto) {
    // Fix cứng user 1 để test
    const userExists = await this.prisma.user.findUnique({
      where: { userId: 1 },
    });

    if (!userExists) {
      await this.prisma.user.create({
        data: {
          userId: 1,
          phoneNumber: '0988888888',
          fullName: 'Test User',
          passwordHash: 'hash123',
          safePinHash: '1234',
          duressPinHash: '9999',
        },
      });
    }

    return this.prisma.trip.create({
      data: {
        userId: 1,
        // Bây giờ TypeScript đã hiểu destinationName là string, không báo lỗi nữa
        destinationName: createTripDto.destinationName,
        durationMinutes: createTripDto.durationMinutes,
        expectedEndTime: new Date(
          Date.now() + createTripDto.durationMinutes * 60000,
        ),
      },
    });
  }

  findAll() {
    return this.prisma.trip.findMany();
  }
}
