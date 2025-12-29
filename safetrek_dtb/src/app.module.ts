import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service';
import { TripsModule } from './trips/trips.module';
import { EmergencyModule } from './emergency/emergency.module';

import { AuthModule } from './auth/auth.module';

@Module({
  imports: [TripsModule, AuthModule, EmergencyModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
