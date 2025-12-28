import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service';
import { TripsModule } from './trips/trips.module';
import { EmergencyModule } from './emergency/emergency.module';

@Module({
  imports: [TripsModule, EmergencyModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
