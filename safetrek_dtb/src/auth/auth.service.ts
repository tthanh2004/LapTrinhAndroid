import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';
import * as nodemailer from 'nodemailer';
import * as bcrypt from 'bcrypt'; // <--- Đã thêm thư viện mã hóa

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private prisma: PrismaService) {
    this.initializeFirebase();
  }

  // ==========================================
  // PHẦN 1: CÁC HÀM BẢO MẬT (HASH & COMPARE)
  // ==========================================

  async hashPassword(plainTextPassword: string): Promise<string> {
    const saltRounds = 10;
    return await bcrypt.hash(plainTextPassword, saltRounds);
  }

  async isPasswordMatch(
    plainTextPassword: string,
    hashedPassword: string,
  ): Promise<boolean> {
    return await bcrypt.compare(plainTextPassword, hashedPassword);
  }

  // ==========================================
  // PHẦN 2: LOGIC ĐĂNG KÝ & ĐĂNG NHẬP MẬT KHẨU
  // ==========================================

  // API Đăng ký (Để tạo user mới với mật khẩu đã mã hóa)
  async register(body: {
    phoneNumber: string;
    password: string;
    fullName: string;
    email?: string;
  }) {
    // 1. Kiểm tra SĐT đã tồn tại chưa
    const existingUser = await this.prisma.user.findUnique({
      where: { phoneNumber: body.phoneNumber },
    });

    if (existingUser) {
      throw new BadRequestException('Số điện thoại này đã được đăng ký.');
    }

    // 2. Mã hóa mật khẩu
    const hashedPassword = await this.hashPassword(body.password);

    // 3. Tạo user mới
    const newUser = await this.prisma.user.create({
      data: {
        phoneNumber: body.phoneNumber,
        passwordHash: hashedPassword, // Lưu vào cột passwordHash theo đúng Schema
        fullName: body.fullName,
        email: body.email,
        // Các trường khác để null hoặc default
      },
    });

    return {
      message: 'Đăng ký thành công',
      userId: newUser.userId,
      fullName: newUser.fullName,
    };
  }

  // API Đăng nhập bằng Mật khẩu
  async loginWithPassword(identity: string, pass: string) {
    // 1. Tìm user (check cả email HOẶC sđt)
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: identity }, { phoneNumber: identity }],
      },
    });

    if (!user) {
      throw new BadRequestException('Tài khoản không tồn tại.');
    }

    // 2. Kiểm tra xem user có mật khẩu không (Trường passwordHash trong Schema)
    if (!user.passwordHash) {
      throw new BadRequestException(
        'Tài khoản này chưa thiết lập mật khẩu (có thể đăng ký bằng OTP).',
      );
    }

    // 3. So sánh mật khẩu bằng bcrypt (An toàn)
    const isMatch = await this.isPasswordMatch(pass, user.passwordHash);

    if (!isMatch) {
      throw new BadRequestException('Mật khẩu không chính xác.');
    }

    // 4. Trả về kết quả
    return {
      message: 'Đăng nhập thành công',
      user: {
        userId: user.userId,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        avatarUrl: user.avatarUrl,
      },
    };
  }

  // ==========================================
  // PHẦN 3: CÁC LOGIC CŨ (FIREBASE, OTP)
  // ==========================================

  private initializeFirebase() {
    if (admin.apps.length === 0) {
      try {
        const serviceAccountPath = path.join(
          process.cwd(),
          'firebase-service-account.json',
        );

        if (!fs.existsSync(serviceAccountPath)) {
          this.logger.error(`❌ Không tìm thấy file: ${serviceAccountPath}`);
          return;
        }

        const fileContent = fs.readFileSync(serviceAccountPath, 'utf8');
        const serviceAccount = JSON.parse(fileContent) as admin.ServiceAccount;

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });

        this.logger.log('🔥 Firebase Admin initialized thành công');
      } catch (error) {
        this.logger.error('❌ Lỗi khởi tạo Firebase:', error);
      }
    }
  }

  async checkLoginMethod(phoneNumber: string) {
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: phoneNumber },
    });

    if (user && user.email) {
      try {
        this.logger.log(`🔍 Tìm thấy email ${user.email}. Đang gửi OTP...`);
        await this.sendEmailOtp(user.email);
        return {
          method: 'EMAIL',
          message: `Mã OTP đã gửi tới ${this.maskEmail(user.email)}`,
          target: user.email,
        };
      } catch (error) {
        let errorMessage = 'Unknown error';
        if (error instanceof Error) errorMessage = error.message;
        this.logger.warn(
          `⚠️ Gửi mail thất bại, chuyển sang SMS. Lỗi: ${errorMessage}`,
        );
      }
    }

    return {
      method: 'SMS',
      message: 'Vui lòng xác thực bằng SMS (Firebase)',
      target: phoneNumber,
    };
  }

  async loginWithFirebase(token: string) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      const phoneNumber = decodedToken.phone_number;

      if (!phoneNumber) {
        throw new UnauthorizedException(
          'Token không chứa số điện thoại hợp lệ',
        );
      }

      this.logger.log(`✅ Xác thực Firebase OK: ${phoneNumber}`);

      const user = await this.prisma.user.upsert({
        where: { phoneNumber: phoneNumber },
        update: {},
        create: {
          phoneNumber: phoneNumber,
          fullName: 'Người dùng mới',
        },
      });

      return {
        message: 'Đăng nhập thành công',
        user: {
          userId: user.userId,
          phoneNumber: user.phoneNumber,
          fullName: user.fullName,
          email: user.email,
        },
      };
    } catch (error) {
      this.logger.error('❌ Lỗi Firebase Admin:', error);
      throw new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn');
    }
  }

  async sendEmailOtp(email: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = new Date(Date.now() + 5 * 60000);

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'thanhtlu2k44@gmail.com',
        pass: 'tezxgrcnmkdwwfoa',
      },
    });

    await transporter.sendMail({
      from: '"SafeTrek Security" <no-reply@safetrek.com>',
      to: email,
      subject: 'Mã xác thực đăng nhập SafeTrek',
      html: `
        <div style="font-family: Arial, sans-serif; text-align: center; border: 1px solid #ddd; padding: 20px; border-radius: 10px; max-width: 500px; margin: auto;">
          <h2 style="color: #2c3e50;">Mã OTP của bạn</h2>
          <p>Sử dụng mã dưới đây để đăng nhập vào SafeTrek:</p>
          <h1 style="color: #e74c3c; letter-spacing: 5px; font-size: 32px; margin: 20px 0;">${otp}</h1>
          <p style="color: #7f8c8d; font-size: 12px;">Mã có hiệu lực trong 5 phút.</p>
        </div>
      `,
    });

    this.logger.log(`📧 Đã gửi OTP tới: ${email}`);

    await this.prisma.user.update({
      where: { email: email },
      data: { otpCode: otp, otpExpiry: expiry },
    });
    return true;
  }

  async verifyEmailOtp(email: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (!user)
      throw new BadRequestException('Không tìm thấy tài khoản email này.');
    if (user.otpCode !== code)
      throw new BadRequestException('Mã OTP không chính xác.');
    if (user.otpExpiry && new Date() > user.otpExpiry)
      throw new BadRequestException('Mã OTP đã hết hạn.');

    const updatedUser = await this.prisma.user.update({
      where: { userId: user.userId },
      data: { otpCode: null, otpExpiry: null },
    });

    return {
      message: 'Đăng nhập thành công',
      user: {
        userId: updatedUser.userId,
        fullName: updatedUser.fullName,
        phoneNumber: updatedUser.phoneNumber,
      },
    };
  }

  private maskEmail(email: string): string {
    if (!email) return '';
    const [name, domain] = email.split('@');
    return name.length <= 2
      ? `${name}***@${domain}`
      : `${name.substring(0, 2)}***@${domain}`;
  }
}
