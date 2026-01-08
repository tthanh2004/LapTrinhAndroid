import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// Import file cấu hình Firebase
import 'firebase_options.dart';

import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/auth/login_screen.dart';
// [MỚI] Import các màn hình và service cần thiết
import 'screens/mobile/mobile_screen.dart';
import 'services/auth_service.dart';
import 'services/background_service.dart';

// Handler xử lý tin nhắn khi app tắt (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Đăng ký background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. [MỚI] Khởi tạo cấu hình chạy nền (Chưa start ngay, chờ user bật trong Cài đặt)
  // Đảm bảo bạn đã tạo file services/background_service.dart như hướng dẫn trước
  await initializeBackgroundService();

  // 4. Xin quyền
  await _requestInitialPermissions();

  // 5. [MỚI] Kiểm tra trạng thái đăng nhập
  final authService = AuthService();
  final loginInfo = await authService.getLoginInfo();
  
  Widget initialScreen = const LoginScreen();

  // Nếu tìm thấy userId và token trong bộ nhớ máy -> Vào thẳng màn hình chính
  if (loginInfo != null && loginInfo['userId'] != null) {
    print("User đã đăng nhập: ID ${loginInfo['userId']}");
    initialScreen = MobileScreen(userId: loginInfo['userId']);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      // Truyền màn hình khởi động vào App
      child: SafeTrekApp(initialScreen: initialScreen),
    ),
  );
}

// Hàm xin quyền khởi động
Future<void> _requestInitialPermissions() async {
  // 1. Quyền GPS
  await Permission.location.request();
  // 2. Quyền Thông báo
  await Permission.notification.request();
}

class SafeTrekApp extends StatefulWidget {
  final Widget? initialScreen; // [MỚI] Nhận màn hình khởi động từ main
  const SafeTrekApp({super.key, this.initialScreen});

  @override
  State<SafeTrekApp> createState() => _SafeTrekAppState();
}

class _SafeTrekAppState extends State<SafeTrekApp> {
  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) async {
    if (message.data['type'] == 'EMERGENCY_PANIC') {
      double lat = double.tryParse(message.data['latitude'].toString()) ?? 0.0;
      double lng = double.tryParse(message.data['longitude'].toString()) ?? 0.0;

      // Link Google Maps chuẩn
      final Uri googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

      try {
        if (await canLaunchUrl(googleUrl)) {
          await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Không thể mở Google Maps');
        }
      } catch (e) {
        debugPrint('Lỗi mở bản đồ: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeTrek',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // [MỚI] Sử dụng màn hình đã xác định (Login hoặc MobileScreen)
      home: widget.initialScreen ?? const LoginScreen(),
    );
  }
}