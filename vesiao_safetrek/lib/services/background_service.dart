import 'dart:async';
import 'dart:convert'; // [FIX] Import để dùng jsonEncode
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart'; // [FIX] Import để dùng Battery()
import 'package:http/http.dart' as http; // [FIX] Import để gọi API
import '../common/constants.dart'; // [FIX] Import để dùng Constants.baseUrl

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

  // Lắng nghe cảm biến gia tốc
  accelerometerEvents.listen((AccelerometerEvent event) {
    double acceleration = event.x.abs() + event.y.abs() + event.z.abs();
    
    // Ngưỡng 35 thường tương ứng với một cú gõ mạnh vào thân máy
    // Nếu quá khó kích hoạt, bạn có thể giảm xuống 25 hoặc 30
    if (acceleration > 35) {
      DateTime now = DateTime.now();
      
      if (now.difference(lastTapTime).inMilliseconds < 600) {
        tapCount++;
      } else {
        tapCount = 1;
      }
      
      lastTapTime = now;

      if (tapCount >= 3) {
        tapCount = 0; // Reset
        _triggerEmergencyFromBackground(service);
      }
    }
  });

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
    // 1. Lấy UserID từ bộ nhớ đệm
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      print("⚠️ Không tìm thấy UserId, không thể gửi API.");
      return;
    }

    // 2. Lấy vị trí GPS
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // 3. Lấy mức Pin hiện tại
    int batteryLevel = await Battery().batteryLevel;

    // 4. Cập nhật thông báo trên thanh trạng thái
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "🆘 ĐÃ GỬI SOS KHẨN CẤP",
        content: "Pin: $batteryLevel%. Đang báo cho người bảo vệ.",
      );
    }

    // 5. Gọi API gửi lên Server (Kèm mức Pin)
    print("🚀 Đang gửi API Panic: User $userId - Pin $batteryLevel%");
    
    final url = Uri.parse('${Constants.baseUrl}/emergency/panic');
    
    final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "lat": position.latitude, 
          "lng": position.longitude,
          "batteryLevel": batteryLevel, 
        }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
       print("✅ Gửi thành công!");
    } else {
       print("❌ Lỗi Server: ${response.body}");
    }

  } catch (e) {
    print("❌ Lỗi kích hoạt cứu hộ ngầm: $e");
  }
}