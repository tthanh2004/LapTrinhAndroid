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

  // 1. Lấy danh sách người bảo vệ
  async getGuardians(userId: number) {
    return this.prisma.guardian.findMany({
      where: { userId },
      orderBy: { guardianId: 'desc' },
    });
  }

  // 2. Thêm người bảo vệ & Tạo thông báo mời
  async addGuardian(userId: number, name: string, phone: string) {
    const count = await this.prisma.guardian.count({ where: { userId } });
    if (count >= 5) throw new BadRequestException('Tối đa 5 người bảo vệ');

    const existing = await this.prisma.guardian.findFirst({
      where: { userId, guardianPhone: phone },
    });
    if (existing) throw new BadRequestException('Đã có trong danh sách');

    // Tạo record Guardian
    const newGuardian = await this.prisma.guardian.create({
      data: {
        userId,
        guardianName: name,
        guardianPhone: phone,
        status: 'PENDING',
      },
    });

    // --- LOGIC THÔNG BÁO ---
    const targetUser = await this.prisma.user.findUnique({
      where: { phoneNumber: phone },
    });

    if (targetUser) {
      const requester = await this.prisma.user.findUnique({
        where: { userId },
      });
      const title = 'Lời mời bảo vệ';
      const body = `${requester?.fullName || 'Ai đó'} muốn thêm bạn làm người bảo vệ.`;

      // a. Lưu vào DB
      await this.prisma.notification.create({
        data: {
          userId: targetUser.userId,
          title: title,
          body: body,
          type: 'GUARDIAN_REQUEST',
          data: JSON.stringify({ guardianId: newGuardian.guardianId }),
        },
      });

      // b. Gửi Push Notification
      if (targetUser.fcmToken) {
        await this._sendPushToToken(targetUser.fcmToken, title, body, {
          type: 'GUARDIAN_REQUEST',
        });
      }
    }

    return newGuardian;
  }

  // 3. Xóa người bảo vệ
  async deleteGuardian(id: number) {
    try {
      return await this.prisma.guardian.delete({ where: { guardianId: id } });
    } catch {
      throw new NotFoundException('Không tìm thấy để xóa');
    }
  }

  // 4. Bắn SOS & Lưu thông báo
  async triggerPanicAlert(userId: number, lat: number, lng: number) {
    const sender = await this.prisma.user.findUnique({ where: { userId } });
    if (!sender) throw new NotFoundException('Không tìm thấy User');

    const guardians = await this.prisma.guardian.findMany({
      where: { userId, status: 'ACCEPTED' },
      select: { guardianPhone: true },
    });

    if (guardians.length === 0)
      return { success: true, message: 'Chưa có người bảo vệ' };

    const guardianPhones = guardians.map((g) => g.guardianPhone);

    const usersToNotify = await this.prisma.user.findMany({
      where: { phoneNumber: { in: guardianPhones } },
      select: { userId: true, fcmToken: true, fullName: true },
    });

    const title = '⚠️ CẢNH BÁO KHẨN CẤP!';
    const body = `${sender.fullName || 'Người thân'} đang gặp nguy hiểm! Nhấn để xem vị trí.`;
    const tokens: string[] = [];

    for (const u of usersToNotify) {
      await this.prisma.notification.create({
        data: {
          userId: u.userId,
          title: title,
          body: body,
          type: 'EMERGENCY',
          data: JSON.stringify({ lat, lng }),
        },
      });
      if (u.fcmToken) tokens.push(u.fcmToken);
    }

    if (tokens.length > 0) {
      await this._sendPushMulticast(tokens, title, body, {
        latitude: lat.toString(),
        longitude: lng.toString(),
        type: 'EMERGENCY_PANIC',
        senderPhone: sender.phoneNumber || '',
      });
    }

    return { success: true, notifiedCount: tokens.length };
  }

  // 5. Lấy danh sách thông báo
  async getUserNotifications(userId: number) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  // --- HELPERS (ĐÃ SỬA LỖI TYPE 'ANY') ---

  private async _sendPushToToken(
    token: string,
    title: string,
    body: string,
    data: { [key: string]: string }, // [SỬA] Thay 'any' bằng object string
  ) {
    try {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: data,
        android: { priority: 'high' },
      });
    } catch (e) {
      console.log('FCM Error', e);
    }
  }

  private async _sendPushMulticast(
    tokens: string[],
    title: string,
    body: string,
    data: { [key: string]: string }, // [SỬA] Thay 'any' bằng object string
  ) {
    try {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: data,
        android: { priority: 'high' },
      });
    } catch (e) {
      console.log('FCM Multicast Error', e);
    }
  }
}
