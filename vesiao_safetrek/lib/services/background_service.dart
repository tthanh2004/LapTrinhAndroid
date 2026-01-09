import 'dart:async';
import 'dart:convert'; // [QUAN TRỌNG] Để dùng jsonEncode
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart'; // [QUAN TRỌNG] Import thư viện Pin
import 'package:http/http.dart' as http; // [QUAN TRỌNG] Import để gọi API
import '../common/constants.dart'; // [QUAN TRỌNG] Đảm bảo đường dẫn này đúng với project của bạn

Future<void> initializeBackgroundService() async {
  if (kIsWeb) return;

  final service = FlutterBackgroundService();
  
  // Kênh thông báo cho Android (Bắt buộc để chạy ngầm)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'SAFE TREK SERVICE',
    description: 'Ứng dụng đang chạy ngầm để bảo vệ bạn',
    importance: Importance.low, 
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (!kIsWeb) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true, // [SỬA] Đặt thành true để tự chạy khi mở app
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'SafeTrek đang hoạt động',
      initialNotificationContent: 'Gõ 3 lần vào máy để gửi SOS',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
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

  // --- LOGIC CẢM BIẾN (TRIPLE TAP) ---
  int tapCount = 0;
  DateTime lastTapTime = DateTime.now();

  // Lắng nghe sự kiện rung lắc
  accelerometerEvents.listen((AccelerometerEvent event) {
    // Tính lực tác động
    double acceleration = event.x.abs() + event.y.abs() + event.z.abs();
    
    // [SỬA] Giảm ngưỡng xuống 20 để dễ test hơn (35 phải gõ rất mạnh)
    if (acceleration > 20) { 
      DateTime now = DateTime.now();
      
      // Nếu 2 cú gõ cách nhau dưới 800ms (tăng nhẹ thời gian chờ)
      if (now.difference(lastTapTime).inMilliseconds < 800) {
        tapCount++;
      } else {
        tapCount = 1;
      }
      
      lastTapTime = now;

      // Nếu gõ đủ 3 lần
      if (tapCount >= 3) {
        tapCount = 0; // Reset
        print("🚨 PHÁT HIỆN GÕ 3 LẦN TỪ NỀN!");
        _triggerEmergencyFromBackground(service);
      }
    }
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());

  // Timer giữ service sống và cập nhật thông báo
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "SafeTrek đang bảo vệ",
          content: "Cảm biến đang bật. Gõ 3 lần để SOS.",
        );
      }
    }
  });
}

// --- HÀM GỬI CỨU HỘ KHI CHẠY NGẦM ---
void _triggerEmergencyFromBackground(ServiceInstance service) async {
  try {
    // 1. Lấy UserID từ bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    // [QUAN TRỌNG] Đảm bảo bạn đã lưu 'userId' dạng int khi đăng nhập
    final userId = prefs.getInt('userId'); 

    if (userId == null) {
      print("⚠️ Lỗi: Không tìm thấy UserId trong bộ nhớ.");
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Lỗi SOS",
          content: "Vui lòng mở app và đăng nhập lại!",
        );
      }
      return;
    }

    // 2. Lấy GPS
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // 3. Lấy Pin (Sử dụng thư viện battery_plus)
    int batteryLevel = await Battery().batteryLevel;

    // 4. Thông báo người dùng biết đã kích hoạt
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "🆘 ĐANG GỬI SOS...",
        content: "Vị trí: ${position.latitude}, ${position.longitude} | Pin: $batteryLevel%",
      );
    }

    print("🚀 Đang gửi API: User $userId | Pin $batteryLevel%");

    // 5. Gọi API
    final url = Uri.parse('${Constants.baseUrl}/emergency/panic');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": userId,
        "lat": position.latitude, 
        "lng": position.longitude,
        "batteryLevel": batteryLevel, // Gửi mức pin
        // "tripId": prefs.getInt('currentTripId') // (Tùy chọn) Nếu có lưu tripId
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
       print("✅ Gửi SOS thành công!");
       if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "✅ ĐÃ GỬI SOS THÀNH CÔNG",
            content: "Người bảo vệ đã nhận được tin nhắn.",
          );
       }
    } else {
       print("❌ Lỗi Server: ${response.body}");
    }

  } catch (e) {
    print("❌ Lỗi ngoại lệ khi gửi SOS ngầm: $e");
  }
}