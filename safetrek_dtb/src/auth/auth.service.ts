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

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private prisma: PrismaService) {
    this.initializeFirebase();
  }

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
        // --- SỬA LỖI 1: Xử lý error message an toàn ---
        let errorMessage = 'Unknown error';
        if (error instanceof Error) {
          errorMessage = error.message;
        }
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
      // --- SỬA LỖI 2: Xóa biến firebaseUid thừa ---

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

    if (!user) {
      throw new BadRequestException('Không tìm thấy tài khoản email này.');
    }

    if (user.otpCode !== code) {
      throw new BadRequestException('Mã OTP không chính xác.');
    }

    if (user.otpExpiry && new Date() > user.otpExpiry) {
      throw new BadRequestException('Mã OTP đã hết hạn. Vui lòng lấy mã mới.');
    }

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
    if (name.length <= 2) {
      return `${name}***@${domain}`;
    }
    return `${name.substring(0, 2)}***@${domain}`;
  }
}
