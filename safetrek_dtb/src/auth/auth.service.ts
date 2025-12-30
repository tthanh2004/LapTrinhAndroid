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

    const existingUser = await this.prisma.user.findUnique({
      where: { phoneNumber: body.phoneNumber },
    });
    if (existingUser)
      throw new BadRequestException('Số điện thoại đã được đăng ký.');

    // Hash dữ liệu song song
    const [passwordHash, safePinHash, duressPinHash] = await Promise.all([
      this.hashData(body.password),
      this.hashData(body.safePin),
      this.hashData(body.duressPin),
    ]);

    const newUser = await this.prisma.user.create({
      data: {
        phoneNumber: body.phoneNumber,
        fullName: body.fullName,
        email: body.email,
        passwordHash: passwordHash,
        safePinHash: safePinHash,
        duressPinHash: duressPinHash,
      },
    });

    return { message: 'Đăng ký thành công', userId: newUser.userId };
  }

  // --- LOGIC CHECK PIN ---
  async verifySafePin(userId: number, pin: string) {
    const user = await this.prisma.user.findUnique({ where: { userId } });
    if (!user || !user.safePinHash)
      throw new UnauthorizedException('Tài khoản lỗi.');

    const isMatch = await this.isDataMatch(pin, user.safePinHash);
    if (!isMatch) throw new UnauthorizedException('Mã PIN không chính xác.');

    return { success: true, message: 'OK' };
  }

  // --- LOGIC LOGIN ---
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
