import { Module } from '@nestjs/common';
import { TripsService } from './trips.service';
import { TripsController } from './trips.controller';
import { PrismaService } from '../prisma.service'; // <-- Đừng quên dòng này

@Module({
  controllers: [TripsController],
  providers: [TripsService, PrismaService], // <-- Đừng quên PrismaService
})
export class TripsModule {}
