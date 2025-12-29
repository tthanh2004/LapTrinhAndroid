import { Body, Controller, Param, ParseIntPipe, Put } from '@nestjs/common';
import { UsersService } from './users.service';
import { ChangePinDto, UpdateProfileDto } from './dto/update-user.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // API Cập nhật thông tin: PUT http://ip:3000/users/1
  @Put(':id')
  async updateProfile(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(id, dto);
  }

  // API Đổi mã PIN: PUT http://ip:3000/users/1/change-pin
  @Put(':id/change-pin')
  async changePin(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ChangePinDto,
  ) {
    return this.usersService.changePin(id, dto);
  }
}
