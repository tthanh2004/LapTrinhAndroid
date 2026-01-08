import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import * as admin from 'firebase-admin';
import { GuardianStatus } from '@prisma/client';

@Injectable()
export class EmergencyService {
  constructor(private prisma: PrismaService) {}

  // =================================================================
  // PHẦN 1: QUẢN LÝ NGƯỜI BẢO VỆ (GUARDIANS)
  // =================================================================

  // 1. Lấy danh sách người bảo vệ
  async getGuardians(userId: number) {
    return this.prisma.guardian.findMany({
      where: { userId },
      orderBy: { guardianId: 'desc' },
    });
  }

  // 2. Thêm người bảo vệ
  async addGuardian(userId: number, name: string, phone: string) {
    const count = await this.prisma.guardian.count({ where: { userId } });
    if (count >= 5) throw new BadRequestException('Tối đa 5 người bảo vệ');

    const existing = await this.prisma.guardian.findFirst({
      where: { userId, guardianPhone: phone },
    });
    if (existing) throw new BadRequestException('Đã có trong danh sách');

    const newGuardian = await this.prisma.guardian.create({
      data: {
        userId,
        guardianName: name,
        guardianPhone: phone,
        status: 'PENDING',
      },
    });

    const targetUser = await this.prisma.user.findUnique({
      where: { phoneNumber: phone },
    });

    if (targetUser) {
      const requester = await this.prisma.user.findUnique({
        where: { userId },
      });
      const title = 'Lời mời bảo vệ';
      const body = `${requester?.fullName || 'Ai đó'} muốn thêm bạn làm người bảo vệ.`;

      await this.prisma.notification.create({
        data: {
          userId: targetUser.userId,
          title: title,
          body: body,
          type: 'GUARDIAN_REQUEST',
          data: JSON.stringify({ guardianId: newGuardian.guardianId }),
        },
      });

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

  // 4. Phản hồi lời mời
  async respondToGuardianRequest(guardianId: number, status: GuardianStatus) {
    const guardian = await this.prisma.guardian.findUnique({
      where: { guardianId },
    });

    if (!guardian) {
      throw new NotFoundException('Lời mời không tồn tại hoặc đã bị hủy');
    }

    return this.prisma.guardian.update({
      where: { guardianId },
      data: { status: status },
    });
  }

  // =================================================================
  // PHẦN 2: BÁO ĐỘNG KHẨN CẤP (PANIC) - LOGIC THÔNG MINH
  // =================================================================

  // 5. Trigger Panic
  async triggerPanicAlert(
    userId: number,
    lat: number,
    lng: number,
    tripId?: number,
  ) {
    console.log(
      `🚨 PANIC ALERT: User ${userId} | Trip: ${tripId} | Loc: [${lat}, ${lng}]`,
    );

    const sender = await this.prisma.user.findUnique({ where: { userId } });
    if (!sender) throw new NotFoundException('Không tìm thấy User');

    // BƯỚC A: Luôn cập nhật vị trí mới nhất vào bảng User
    await this.prisma.user.update({
      where: { userId },
      data: {
        lastKnownLat: lat,
        lastKnownLng: lng,
      },
    });

    // BƯỚC B: Tạo Alert (Ghi nhận sự kiện)
    await this.prisma.alert.create({
      data: {
        userId: userId,
        tripId: tripId, // Nếu null thì thôi
        alertType: 'PANIC_BUTTON',
      },
    });

    // BƯỚC C: Chỉ lưu vào TripLocation NẾU đang có chuyến đi (tripId tồn tại)
    if (tripId) {
      try {
        await this.prisma.tripLocation.create({
          data: {
            tripId: tripId,
            lat: lat,
            lng: lng,
          },
        });
        console.log('✅ Đã lưu điểm Panic vào lịch sử TripLocation');
      } catch (e) {
        console.warn(
          '⚠️ Lỗi lưu TripLocation (Có thể tripId không hợp lệ):',
          e,
        );
      }
    }

    // BƯỚC D: Gửi thông báo cho người thân
    const guardians = await this.prisma.guardian.findMany({
      where: { userId, status: 'ACCEPTED' },
      select: { guardianPhone: true },
    });

    if (guardians.length === 0)
      return { success: true, message: 'Đã lưu Alert (Chưa có người bảo vệ)' };

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
          // Lưu tọa độ vào data để App người thân bấm vào là nhảy tới map
          data: JSON.stringify({ lat, lng, tripId }),
        },
      });
      if (u.fcmToken) tokens.push(u.fcmToken);
    }

    if (tokens.length > 0) {
      const fcmData: Record<string, string> = {
        latitude: lat.toString(),
        longitude: lng.toString(),
        type: 'EMERGENCY_PANIC',
        senderPhone: sender.phoneNumber || '',
      };

      await this._sendPushMulticast(tokens, title, body, fcmData);
    }

    return { success: true, notifiedCount: tokens.length };
  }

  // =================================================================
  // PHẦN 3: THÔNG BÁO & TIỆN ÍCH KHÁC
  // =================================================================

  // 6. Lấy danh sách thông báo (Kèm status lời mời nếu có)
  async getUserNotifications(userId: number) {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return await Promise.all(
      notifications.map(async (notif) => {
        let extraInfo = {};
        if (notif.type === 'GUARDIAN_REQUEST' && notif.data) {
          try {
            const dataObj = JSON.parse(notif.data) as { guardianId: number };
            const guardianId = dataObj.guardianId;

            const guardian = await this.prisma.guardian.findUnique({
              where: { guardianId },
              select: { status: true },
            });
            if (guardian) {
              extraInfo = { currentGuardianStatus: guardian.status };
            }
          } catch (e) {
            console.error('Error parsing notification data:', e);
          }
        }
        return { ...notif, ...extraInfo };
      }),
    );
  }

  // 7. Lấy danh sách người tôi đang bảo vệ
  async getPeopleIProtect(myUserId: number) {
    const me = await this.prisma.user.findUnique({
      where: { userId: myUserId },
    });

    if (!me || !me.phoneNumber) return [];

    const records = await this.prisma.guardian.findMany({
      where: { guardianPhone: me.phoneNumber },
      include: { user: true },
      orderBy: { status: 'asc' },
    });

    return records.map((r) => ({
      guardianId: r.guardianId,
      status: r.status,
      protectedUser: {
        userId: r.user.userId,
        fullName: r.user.fullName ?? 'Không tên',
        phoneNumber: r.user.phoneNumber,
        avatarUrl: r.user.avatarUrl,
      },
    }));
  }

  // 8. Đếm thông báo chưa đọc
  async getUnreadCount(userId: number) {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }

  // 9. Đánh dấu tất cả đã đọc
  async markAllAsRead(userId: number) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }

  // 10. Gửi thông báo thủ công (Test)
  async sendManualNotification(userId: number, title: string, body: string) {
    const user = await this.prisma.user.findUnique({ where: { userId } });
    if (user?.fcmToken) {
      await this._sendPushToToken(user.fcmToken, title, body, {
        type: 'NORMAL_MESSAGE',
      });
      return { success: true };
    }
    return { success: false, message: 'User has no token' };
  }

  // --- HELPERS (FCM) ---

  private async _sendPushToToken(
    token: string,
    title: string,
    body: string,
    data: { [key: string]: string },
  ) {
    try {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data,
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
    data: { [key: string]: string },
  ) {
    try {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data,
        android: { priority: 'high' },
      });
    } catch (e) {
      console.log('FCM Multicast Error', e);
    }
  }
}
