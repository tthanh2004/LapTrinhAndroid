import { Module } from '@nestjs/common';
import { TripsService } from './trips.service';
import { TripsController } from './trips.controller';
import { PrismaService } from '../prisma.service'; // <--- Import

@Module({
  controllers: [TripsController],
  providers: [TripsService, PrismaService], // <--- Thêm PrismaService
})
export class TripsModule {}
