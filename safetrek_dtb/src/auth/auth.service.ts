import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';
import * as nodemailer from 'nodemailer';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    if (admin.apps.length === 0) {
      try {
        const serviceAccountPath = path.resolve(
          'firebase-service-account.json',
        );
        const fileContent = fs.readFileSync(serviceAccountPath, 'utf8');
        const serviceAccount = JSON.parse(fileContent) as admin.ServiceAccount;

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });

        console.log('🔥 Firebase Admin initialized');
      } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error);
      }
    }
  }

  /**
   * Bước 1: Kiểm tra xem nên đăng nhập bằng Email hay SMS
   * (Logic mới bạn yêu cầu)
   */
  async checkLoginMethod(phoneNumber: string) {
    // Tìm user bằng SĐT
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: phoneNumber },
    });

    // Nếu User tồn tại và đã lưu Email -> Gửi OTP về Email
    if (user && user.email) {
      console.log(`🔍 Tìm thấy email ${user.email}. Đang gửi OTP...`);
      await this.sendEmailOtp(user.email);

      return {
        method: 'EMAIL',
        message: `Mã OTP đã được gửi tới email ${this.maskEmail(user.email)}`,
        target: user.email, // Trả về email để Flutter hiển thị
      };
    }

    // Nếu chưa có Email hoặc User mới -> Dùng SMS (Firebase)
    return {
      method: 'SMS',
      message: 'Vui lòng xác thực qua SMS (Firebase)',
      target: phoneNumber,
    };
  }

  /**
   * Đăng nhập bằng Firebase Token (Dành cho SĐT - Bước cuối)
   */
  async loginWithFirebase(token: string) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      const phoneNumber = decodedToken.phone_number;

      if (!phoneNumber) {
        throw new UnauthorizedException('Token không chứa số điện thoại');
      }

      console.log(`✅ Xác thực Firebase thành công: ${phoneNumber}`);

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
        userId: user.userId,
        phoneNumber: user.phoneNumber,
        fullName: user.fullName,
      };
    } catch (error: unknown) {
      let errorMessage = 'Unknown error';
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      console.error('❌ Lỗi Firebase Admin:', errorMessage);
      throw new UnauthorizedException(
        'Mã xác thực không hợp lệ hoặc đã hết hạn',
      );
    }
  }

  /**
   * Gửi mã OTP qua Gmail
   */
  async sendEmailOtp(email: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = new Date(Date.now() + 5 * 60000); // 5 phút

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'thanhtlu2k44@gmail.com',
        // Đã sửa lỗi khoảng trắng trong mật khẩu của bạn
        pass: 'tezxgrcnmkdwwfoa',
      },
    });

    try {
      await transporter.sendMail({
        from: '"SafeTrek Support" <no-reply@safetrek.com>',
        to: email,
        subject: 'Mã xác thực đăng nhập SafeTrek',
        html: `
          <div style="font-family: Arial; text-align: center; border: 1px solid #eee; padding: 20px;">
            <h2 style="color: #333;">Mã xác thực SafeTrek</h2>
            <p>Mã OTP đăng nhập của bạn là:</p>
            <h1 style="color: #FF5722; letter-spacing: 10px; font-size: 40px;">${otp}</h1>
            <p style="color: #777;">Hết hạn sau 5 phút.</p>
          </div>
        `,
      });

      console.log(`📧 OTP Sent to: ${email}`);

      // Lưu OTP vào DB nhưng KHÔNG tạo user mới nếu chưa có (vì login bằng SĐT update vào user có sẵn)
      // Dùng updateMany để chỉ update nếu email đã tồn tại
      await this.prisma.user.update({
        where: { email: email },
        data: { otpCode: otp, otpExpiry: expiry },
      });

      return { message: 'OTP đã được gửi vào hòm thư.' };
    } catch (error: unknown) {
      console.error('❌ Lỗi gửi mail:', error);
      throw new BadRequestException('Không thể gửi email lúc này.');
    }
  }

  /**
   * Xác thực mã OTP Gmail
   */
  async verifyEmailOtp(email: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (!user || user.otpCode !== code) {
      throw new BadRequestException('Mã OTP không đúng.');
    }

    if (user.otpExpiry && new Date() > user.otpExpiry) {
      throw new BadRequestException('Mã OTP đã hết hạn.');
    }

    await this.prisma.user.update({
      where: { userId: user.userId },
      data: { otpCode: null, otpExpiry: null },
    });

    return {
      message: 'Đăng nhập thành công',
      userId: user.userId,
      fullName: user.fullName,
    };
  }

  // Helper: Che bớt email (vd: t***@gmail.com)
  private maskEmail(email: string): string {
    const [name, domain] = email.split('@');
    return `${name.substring(0, 2)}***@${domain}`;
  }
}
