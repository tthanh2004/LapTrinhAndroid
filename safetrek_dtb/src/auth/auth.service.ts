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
    password: string;
    fullName: string;
    email?: string;
    safePin: string;
    duressPin: string;
  }) {
    // 1. Validate
    if (
      !body.phoneNumber ||
      !body.password ||
      !body.safePin ||
      !body.duressPin
    ) {
      throw new BadRequestException('Vui lòng nhập đầy đủ thông tin và PIN.');
    }
    if (body.safePin === body.duressPin) {
      throw new BadRequestException('Hai mã PIN không được trùng nhau.');
    }

    // 2. Kiểm tra trùng lặp (SĐT và Email)
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

    // 3. Mã hóa dữ liệu (Hash)
    const [passwordHash, safePinHash, duressPinHash] = await Promise.all([
      this.hashData(body.password),
      this.hashData(body.safePin),
      this.hashData(body.duressPin),
    ]);

    // 4. Lưu vào DB (Map đúng với schema.prisma)
    const newUser = await this.prisma.user.create({
      data: {
        phoneNumber: body.phoneNumber,
        fullName: body.fullName,
        email: body.email,
        passwordHash: passwordHash,
        safePinHash: safePinHash, // Lưu vào cột safe_pin_hash
        duressPinHash: duressPinHash, // Lưu vào cột duress_pin_hash
      },
    });

    return { message: 'Đăng ký thành công', userId: newUser.userId };
  }

  // --- LOGIC CHECK PIN (Dùng cho màn hình nhập PIN sau login) ---
  async verifySafePin(userId: number, pin: string) {
    const user = await this.prisma.user.findUnique({ where: { userId } });

    // Kiểm tra user và xem đã có PIN chưa
    if (!user || !user.safePinHash)
      throw new UnauthorizedException('Tài khoản lỗi hoặc chưa thiết lập PIN.');

    // So sánh PIN nhập vào với Hash trong DB
    const isMatch = await this.isDataMatch(pin, user.safePinHash);
    if (!isMatch) throw new UnauthorizedException('Mã PIN không chính xác.');

    return { success: true, message: 'OK' };
  }

  // --- LOGIC LOGIN ---
  async loginWithPassword(identity: string, pass: string) {
    // Tìm user theo SĐT hoặc Email
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ phoneNumber: identity }, { email: identity }],
      },
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
