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
}
