import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {}

  private async hashData(plainText: string): Promise<string> {
    return await bcrypt.hash(plainText, 10);
  }

  private async isDataMatch(
    plainText: string,
    hashedData: string,
  ): Promise<boolean> {
    return await bcrypt.compare(plainText, hashedData);
  }

  // --- LOGIC ĐĂNG KÝ GỘP ---
  async register(body: {
    phoneNumber: string;
    passwordHash: string; // [SỬA] Đổi tên cho khớp Controller
    fullName: string;
    email?: string;
    safePinHash: string; // [SỬA] Đổi tên cho khớp Controller
    duressPinHash: string; // [SỬA] Đổi tên cho khớp Controller
  }) {
    // 1. Validate (Dùng tên biến mới)
    if (
      !body.phoneNumber ||
      !body.passwordHash ||
      !body.safePinHash ||
      !body.duressPinHash
    ) {
      throw new BadRequestException('Vui lòng nhập đầy đủ thông tin và PIN.');
    }
    if (body.safePinHash === body.duressPinHash) {
      throw new BadRequestException('Hai mã PIN không được trùng nhau.');
    }

    // 2. Kiểm tra trùng lặp
    const existingUser = await this.prisma.user.findUnique({
      where: { phoneNumber: body.phoneNumber },
    });
    if (existingUser)
      throw new BadRequestException('Số điện thoại đã được đăng ký.');

    if (body.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: body.email },
      });
      if (existingEmail)
        throw new BadRequestException('Email đã được sử dụng.');
    }

    // 3. Mã hóa dữ liệu (Lấy dữ liệu từ biến ...Hash để băm)
    const [finalPasswordHash, finalSafePinHash, finalDuressPinHash] =
      await Promise.all([
        this.hashData(body.passwordHash), // Hash mật khẩu
        this.hashData(body.safePinHash), // Hash Safe PIN
        this.hashData(body.duressPinHash), // Hash Duress PIN
      ]);

    // 4. Lưu vào DB
    const newUser = await this.prisma.user.create({
      data: {
        phoneNumber: body.phoneNumber,
        fullName: body.fullName,
        email: body.email,
        passwordHash: finalPasswordHash, // Lưu kết quả đã hash
        safePinHash: finalSafePinHash, // Lưu kết quả đã hash
        duressPinHash: finalDuressPinHash, // Lưu kết quả đã hash
      },
    });

    return { message: 'Đăng ký thành công', userId: newUser.userId };
  }

  // ... (Giữ nguyên các hàm verifySafePin và loginWithPassword)
  async verifySafePin(userId: number, pin: string) {
    const user = await this.prisma.user.findUnique({ where: { userId } });
    if (!user || !user.safePinHash)
      throw new UnauthorizedException('Tài khoản lỗi.');
    const isMatch = await this.isDataMatch(pin, user.safePinHash);
    if (!isMatch) throw new UnauthorizedException('Mã PIN không chính xác.');
    return { success: true, message: 'OK' };
  }

  async loginWithPassword(identity: string, pass: string) {
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ phoneNumber: identity }, { email: identity }] },
    });
    if (!user) throw new UnauthorizedException('Tài khoản không tồn tại.');
    if (!user.passwordHash)
      throw new UnauthorizedException('Tài khoản chưa có mật khẩu.');
    const isMatch = await this.isDataMatch(pass, user.passwordHash);
    if (!isMatch) throw new UnauthorizedException('Mật khẩu không chính xác.');
    return {
      message: 'Đăng nhập thành công',
      user: {
        userId: user.userId,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        email: user.email,
        avatarUrl: user.avatarUrl,
      },
    };
  }
}
