import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
// [MỚI] Thư viện cảm biến để nhận diện gõ máy
import 'package:sensors_plus/sensors_plus.dart';

Future<void> initializeBackgroundService() async {
  if (kIsWeb) return;

  final service = FlutterBackgroundService();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'SAFE TREK BACKGROUND SERVICE',
    description: 'Kênh này được sử dụng cho các thông báo bảo vệ quan trọng.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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

  // --- LOGIC NHẬN DIỆN GÕ MÁY (TRIPLE TAP PHYSICAL) ---
  int tapCount = 0;
  DateTime lastTapTime = DateTime.now();

  // Lắng nghe cảm biến gia tốc (Accelerometer)
  accelerometerEvents.listen((AccelerometerEvent event) {
    // Tính toán độ lớn vector lực tác động
    double acceleration = event.x.abs() + event.y.abs() + event.z.abs();
    
    // Ngưỡng 35 thường tương ứng với một cú gõ mạnh vào thân máy
    if (acceleration > 35) {
      DateTime now = DateTime.now();
      
      // Nếu cú gõ tiếp theo cách cú gõ trước dưới 600ms thì tính là liên tiếp
      if (now.difference(lastTapTime).inMilliseconds < 600) {
        tapCount++;
      } else {
        tapCount = 1;
      }
      
      lastTapTime = now;

      // Khi gõ đủ 3 lần dồn dập
      if (tapCount >= 3) {
        tapCount = 0; // Reset
        _triggerEmergencyFromBackground(service);
      }
    }
  });

  // --- CÁC LOGIC CŨ GIỮ NGUYÊN ---
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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

// --- HÀM XỬ LÝ GỬI CỨU HỘ KHI ĐANG CHẠY NGẦM ---
void _triggerEmergencyFromBackground(ServiceInstance service) async {
  try {
    // 1. Lấy vị trí ngay lập tức
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // 2. Cập nhật thông báo khẩn cấp lên thanh trạng thái (Chuẩn Figma)
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "🆘 ĐÃ GỬI SOS KHẨN CẤP",
        content: "Phát hiện gõ máy 3 lần. Đang báo cho người bảo vệ.",
      );
    }

    // 3. Tại đây bạn gọi API Panic của mình (Sử dụng http post)
    // Lưu ý: userId cần được lưu trữ bền vững (SharedPreferences) để lấy ra ở Isolate này
    print("🚨 BACKGROUND PANIC SENT: ${position.latitude}, ${position.longitude}");
  } catch (e) {
    print("Lỗi kích hoạt cứu hộ ngầm: $e");
  }
}