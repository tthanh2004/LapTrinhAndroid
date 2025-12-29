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
      orderBy: { guardianId: 'desc' }, // Sửa: id -> guardianId
    });
  }

  // 2. Thêm người bảo vệ mới
  async addGuardian(userId: number, name: string, phone: string) {
    const count = await this.prisma.guardian.count({ where: { userId } });
    if (count >= 5) {
      throw new BadRequestException(
        'Bạn chỉ được phép thêm tối đa 5 người bảo vệ',
      );
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
    return this.prisma.guardian.delete({
      where: { guardianId: id }, // Sửa: id -> guardianId
    });
  }

  // 4. Bắn thông báo khẩn cấp (Panic Alert)
  async triggerPanicAlert(userId: number, lat: number, lng: number) {
    const sender = await this.prisma.user.findUnique({ where: { userId } });
    if (!sender) throw new NotFoundException('Không tìm thấy người dùng');

    const guardians = await this.prisma.guardian.findMany({
      where: { userId, status: 'ACCEPTED' },
    });

    const guardianPhones = guardians.map((g) => g.guardianPhone);

    const usersToNotify = await this.prisma.user.findMany({
      where: { phoneNumber: { in: guardianPhones } },
      select: { fcmToken: true },
    });

    const tokens = usersToNotify
      .map((u) => u.fcmToken)
      .filter((t): t is string => t !== null && t !== '');

    if (tokens.length === 0) {
      return {
        success: true,
        message:
          'Ghi nhận vị trí nhưng không có thiết bị người thân nào để gửi thông báo',
      };
    }

    // Fix lỗi: Type string | null không được gán cho string
    const payloadData: { [key: string]: string } = {
      latitude: lat.toString(),
      longitude: lng.toString(),
      type: 'EMERGENCY_PANIC',
      senderPhone: sender.phoneNumber ?? 'Unknown',
    };

    const payload = {
      notification: {
        title: '⚠️ BÁO ĐỘNG KHẨN CẤP!',
        body: `${sender.fullName || 'Người dùng'} đang gặp nguy hiểm!`,
      },
      data: payloadData,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: payload.notification,
        data: payload.data,
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'emergency_channel' },
        },
      });

      return { success: true, notifiedCount: response.successCount };
    } catch (error: unknown) {
      // Fix lỗi unsafe return/any
      const message = error instanceof Error ? error.message : 'Unknown error';
      console.error('❌ Lỗi FCM:', message);
      throw new BadRequestException('Lỗi khi gửi thông báo qua Firebase');
    }
  }
}
