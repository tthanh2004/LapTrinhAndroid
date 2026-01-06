import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  ParseIntPipe,
} from '@nestjs/common';
import { EmergencyService } from './emergency.service';
import { GuardianStatus } from '@prisma/client';

@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergencyService: EmergencyService) {}

  @Get('guardians/:userId')
  async getGuardians(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getGuardians(userId);
  }

  @Post('guardians')
  async addGuardian(
    @Body() body: { userId: number; name: string; phone: string },
  ) {
    return this.emergencyService.addGuardian(
      body.userId,
      body.name,
      body.phone,
    );
  }

  @Delete('guardians/:id')
  async deleteGuardian(@Param('id', ParseIntPipe) id: number) {
    return this.emergencyService.deleteGuardian(id);
  }

  // [MỚI] API Phản hồi (Chấp nhận/Từ chối)
  @Post('guardians/respond')
  async respondToRequest(
    @Body() body: { guardianId: number; status: 'ACCEPTED' | 'REJECTED' },
  ) {
    const statusEnum =
      body.status === 'ACCEPTED'
        ? GuardianStatus.ACCEPTED
        : GuardianStatus.REJECTED;
    return this.emergencyService.respondToGuardianRequest(
      body.guardianId,
      statusEnum,
    );
  }

  @Post('panic')
  async triggerPanic(
    @Body() body: { userId: number; lat: number; lng: number },
  ) {
    return this.emergencyService.triggerPanicAlert(
      body.userId,
      body.lat,
      body.lng,
    );
  }

  @Get('notifications/:userId')
  async getNotifications(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getUserNotifications(userId);
  }
  @Get('protecting/:userId')
  async getPeopleIProtect(@Param('userId', ParseIntPipe) userId: number) {
    return this.emergencyService.getPeopleIProtect(userId);
  }
}
