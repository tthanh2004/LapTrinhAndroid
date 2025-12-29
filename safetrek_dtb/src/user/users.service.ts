import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { ChangePinDto, UpdateProfileDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  // 1. Cập nhật thông tin cá nhân (Tên & Email)
  async updateProfile(userId: number, dto: UpdateProfileDto) {
    // Kiểm tra xem email đã có ai dùng chưa (trừ chính user này)
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser && existingUser.userId !== userId) {
      throw new BadRequestException(
        'Email này đã được sử dụng bởi tài khoản khác.',
      );
    }

    return this.prisma.user.update({
      where: { userId: userId },
      data: {
        fullName: dto.fullName,
        email: dto.email,
      },
      select: { userId: true, fullName: true, email: true, phoneNumber: true },
    });
  }

  // 2. Đổi mã PIN
  async changePin(userId: number, dto: ChangePinDto) {
    const user = await this.prisma.user.findUnique({ where: { userId } });
    if (!user) throw new NotFoundException('User not found');

    // Kiểm tra trùng nhau
    if (dto.safePin === dto.duressPin) {
      throw new BadRequestException(
        'Mã PIN an toàn và khẩn cấp không được trùng nhau.',
      );
    }

    // SỬA Ở ĐÂY: Dùng safePinHash thay vì safePin để khớp với CSDL
    if (user.safePinHash) {
      if (!dto.oldPin) {
        throw new BadRequestException(
          'Vui lòng nhập mã PIN hiện tại để xác thực.',
        );
      }

      // So sánh với safePinHash trong DB
      const isMatch = await bcrypt.compare(dto.oldPin, user.safePinHash);
      if (!isMatch) {
        throw new BadRequestException('Mã PIN hiện tại không chính xác.');
      }
    }

    // Mã hóa
    const salt = await bcrypt.genSalt(10);
    const hashedSafePin = await bcrypt.hash(dto.safePin, salt);
    const hashedDuressPin = await bcrypt.hash(dto.duressPin, salt);

    // SỬA Ở ĐÂY: Lưu vào safePinHash/duressPinHash và BỎ isPinSet
    await this.prisma.user.update({
      where: { userId },
      data: {
        safePinHash: hashedSafePin, // Khớp tên cột trong DB cũ
        duressPinHash: hashedDuressPin, // Khớp tên cột trong DB cũ
        // isPinSet: true -> Đã xóa dòng này vì DB bạn chưa có cột này
      },
    });

    return { message: 'Đổi mã PIN thành công' };
  }
}
