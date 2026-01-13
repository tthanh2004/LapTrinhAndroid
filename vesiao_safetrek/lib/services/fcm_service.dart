// lib/services/fcm_service.dart

import 'dart:convert';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'user_service.dart'; // Import UserService của bạn

// 1. Hàm xử lý tin nhắn khi tắt App (Phải để ở Top-level, ngoài class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🌙 Nhận tin nhắn ngầm: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();
  
  // Plugin hiển thị thông báo cục bộ (để hiện khi đang mở App)
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Khởi tạo
  Future<void> init(int? userId) async {
    // 1. Xin quyền
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    // 2. Lấy Token & Gửi lên Server (Nếu có userId)
    if (userId != null) {
      String? token = await _messaging.getToken();
      if (token != null) {
        print("🔥 FCM Token: $token");
        await _userService.updateFcmToken(userId, token);
      }
    }

    // 3. Cài đặt kênh thông báo cho Android (Quan trọng!)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Id phải khớp với Manifest
      'Cảnh báo Khẩn cấp', // Tên hiển thị trong Cài đặt
      description: 'Kênh thông báo cho các tin nhắn SOS',
      importance: Importance.max, // Max để nó hiện pop-up (Heads-up)
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Cài đặt hiển thị Local Notification
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Icon app
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    // 5. Đăng ký hàm chạy nền
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Lắng nghe tin nhắn khi App đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("☀️ Có tin nhắn khi đang mở app: ${message.notification?.title}");
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Nếu có thông báo -> Tự vẽ ra bằng LocalNotification
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
              color: const Color(0xFFDC2626),            ),
          ),
          payload: jsonEncode(message.data), // Lưu data để xử lý khi bấm vào
        );
      }
    });
  }
}