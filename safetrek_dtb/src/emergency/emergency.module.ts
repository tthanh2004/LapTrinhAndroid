import { Module } from '@nestjs/common';
import { EmergencyService } from './emergency.service';
import { EmergencyController } from './emergency.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [EmergencyController],
  providers: [EmergencyService, PrismaService],
})
export class EmergencyModule {}
