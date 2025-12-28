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

        // Ép kiểu tường minh để tránh lỗi no-unsafe-assignment
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
   * Đăng nhập bằng Firebase Token (Dành cho SĐT)
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
   * Gửi mã OTP qua Gmail (Dành cho Email)
   */
  async sendEmailOtp(email: string) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = new Date(Date.now() + 5 * 60000); // 5 phút

    // Sử dụng nodemailer đã import đúng chuẩn
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'EMAIL_CUA_BAN@gmail.com', // Thay bằng email của bạn
        pass: 'MAT_KHAU_UNG_DUNG_16_KY_TU', // Thay bằng App Password 16 ký tự
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
            <p>Chào bạn, mã OTP để đăng nhập vào ứng dụng của bạn là:</p>
            <h1 style="color: #FF5722; letter-spacing: 10px; font-size: 40px;">${otp}</h1>
            <p style="color: #777;">Mã này sẽ hết hạn trong 5 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
          </div>
        `,
      });

      console.log(`📧 OTP Sent to: ${email}`);

      await this.prisma.user.upsert({
        where: { email: email },
        update: { otpCode: otp, otpExpiry: expiry },
        create: {
          email: email,
          otpCode: otp,
          otpExpiry: expiry,
          fullName: 'Người dùng Gmail',
        },
      });

      return { message: 'OTP đã được gửi vào hòm thư của bạn.' };
    } catch (error: unknown) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error('❌ Lỗi gửi mail:', errorMsg);
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

    // Xóa mã sau khi dùng xong để bảo mật
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
}
