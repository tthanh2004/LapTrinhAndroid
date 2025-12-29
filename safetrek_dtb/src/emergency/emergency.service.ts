import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as admin from 'firebase-admin';

@Injectable()
export class EmergencyService {
  constructor(private prisma: PrismaService) {}

  // 1. Lấy danh sách người bảo vệ (Dùng guardianId)
  async getGuardians(userId: number) {
    return this.prisma.guardian.findMany({
      where: { userId },
      orderBy: { guardianId: 'desc' },
    });
  }

  // 2. Thêm người bảo vệ mới (Gửi lời mời)
  async addGuardian(userId: number, name: string, phone: string) {
    const count = await this.prisma.guardian.count({ where: { userId } });
    if (count >= 5) {
      throw new BadRequestException(
        'Bạn chỉ được phép thêm tối đa 5 người bảo vệ',
      );
    }

    const existing = await this.prisma.guardian.findFirst({
      where: { userId, guardianPhone: phone },
    });
    if (existing) {
      throw new BadRequestException('Người bảo vệ này đã có trong danh sách');
    }

    return this.prisma.guardian.create({
      data: {
        userId,
        guardianName: name,
        guardianPhone: phone,
        status: 'PENDING',
      },
    });
  }

  // 3. Xóa người bảo vệ (Dùng guardianId)
  async deleteGuardian(id: number) {
    try {
      return await this.prisma.guardian.delete({
        where: { guardianId: id },
      });
    } catch {
      // Không khai báo biến ở đây nữa, xóa sạch (_error)
      throw new NotFoundException('Không tìm thấy người bảo vệ để xóa');
    }
  }

  // 4. Bắn thông báo khẩn cấp (Panic Alert)
  async triggerPanicAlert(userId: number, lat: number, lng: number) {
    const sender = await this.prisma.user.findUnique({ where: { userId } });
    if (!sender) throw new NotFoundException('Không tìm thấy người dùng');

    const guardians = await this.prisma.guardian.findMany({
      where: { userId, status: 'ACCEPTED' },
      select: { guardianPhone: true },
    });

    if (guardians.length === 0) {
      return {
        success: true,
        message: 'Chưa có người bảo vệ nào xác nhận kết nối.',
      };
    }

    const guardianPhones = guardians.map((g) => g.guardianPhone);

    const usersToNotify = await this.prisma.user.findMany({
      where: {
        phoneNumber: { in: guardianPhones },
        fcmToken: { not: null },
      },
      select: { fcmToken: true, fullName: true },
    });

    const tokens = usersToNotify
      .map((u) => u.fcmToken)
      .filter((t): t is string => !!t);

    if (tokens.length === 0) {
      return {
        success: true,
        message: 'Người thân chưa đăng nhập vào ứng dụng để nhận thông báo',
      };
    }

    const payloadData: { [key: string]: string } = {
      latitude: lat.toString(),
      longitude: lng.toString(),
      type: 'EMERGENCY_PANIC',
      senderName: sender.fullName || 'Người dùng SafeTrek',
      senderPhone: sender.phoneNumber ?? 'Không có SĐT',
    };

    const message: admin.messaging.MulticastMessage = {
      tokens: tokens,
      notification: {
        title: '⚠️ CẢNH BÁO KHẨN CẤP!',
        body: `${sender.fullName || 'Một người dùng'} đang gặp nguy hiểm! Nhấn để xem vị trí ngay.`,
      },
      data: payloadData,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'emergency_channel',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            mutableContent: true,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `✅ SOS signal sent. Success: ${response.successCount}, Failure: ${response.failureCount}`,
      );

      return {
        success: true,
        notifiedCount: response.successCount,
        failedCount: response.failureCount,
      };
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      console.error('❌ Lỗi Firebase Cloud Messaging:', errorMessage);
      throw new BadRequestException(
        'Hệ thống thông báo gặp lỗi, vui lòng thử lại',
      );
    }
  }
}
