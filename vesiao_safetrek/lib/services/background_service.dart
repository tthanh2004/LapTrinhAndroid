import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

// Hàm khởi tạo Service (Hàm này được gọi ở main.dart)
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Tạo kênh thông báo cho Android (bắt buộc để chạy foreground service)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, 
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // Hàm này sẽ được gọi khi service bắt đầu chạy
      onStart: onStart,

      // Tự động chạy khi app mở hay không? -> Để false để user tự bật trong Cài đặt
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

// Hàm xử lý cho iOS (bắt buộc phải có dù trả về true)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// Hàm chính chạy ngầm (Background Logic)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Đảm bảo Dart đã sẵn sàng
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

  // Vòng lặp chạy ngầm: Ví dụ mỗi 10 giây lấy tọa độ 1 lần
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        
        // 1. Lấy tọa độ GPS
        // Lưu ý: Cần xử lý check quyền ở đây nếu cần thiết, 
        // nhưng thường quyền đã được xin ở UI chính rồi.
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          print('📍 BG Location: ${position.latitude}, ${position.longitude}');
          
          // 2. Cập nhật thông báo để người dùng biết app đang chạy
          service.setForegroundNotificationInfo(
            title: "SafeTrek đang bảo vệ",
            content: "Vị trí hiện tại: ${position.latitude}, ${position.longitude}",
          );

          // 3. (Tùy chọn) Gửi tọa độ lên Server để tracking
          // final response = await http.post(...)
          
        } catch (e) {
          print("Lỗi lấy tọa độ ngầm: $e");
        }
      }
    }
  });
}