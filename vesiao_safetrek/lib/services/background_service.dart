import 'dart:async';
import 'dart:ui';
// [MỚI] Import để check nền tảng Web
import 'package:flutter/foundation.dart'; 

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

Future<void> initializeBackgroundService() async {
  // [QUAN TRỌNG] Chặn code này chạy trên Web
  if (kIsWeb) {
    print("⚠️ Đang chạy trên Web: Bỏ qua FlutterBackgroundService");
    return; 
  }

  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', 
    'MY FOREGROUND SERVICE', 
    description: 'This channel is used for important notifications.', 
    importance: Importance.low, 
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Chỉ chạy tạo channel trên Mobile (Android)
  if (!kIsWeb) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, 
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'SafeTrek Service',
      initialNotificationContent: 'Đang bảo vệ bạn trong nền...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          print('📍 BG Location: ${position.latitude}, ${position.longitude}');
          
          service.setForegroundNotificationInfo(
            title: "SafeTrek đang bảo vệ",
            content: "Vị trí hiện tại: ${position.latitude}, ${position.longitude}",
          );
        } catch (e) {
          print("Lỗi lấy tọa độ ngầm: $e");
        }
      }
    }
  });
}