import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// [QUAN TRỌNG] Import file cấu hình Firebase đã tạo
import 'firebase_options.dart'; 

import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/auth/login_screen.dart';

// Handler xử lý tin nhắn khi app tắt (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // [SỬA] Phải truyền options vào đây để chạy được trên Web/Android
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [SỬA] Sử dụng DefaultFirebaseOptions để tự động chọn cấu hình cho Web/Android/iOS
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Đăng ký background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Xin quyền ngay khi khởi động
  await _requestInitialPermissions();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      child: const SafeTrekApp(),
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
  const SafeTrekApp({super.key});

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
    // 1. Xin quyền thông báo từ Firebase (quan trọng cho iOS/Web)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Lấy thông báo khiến app mở từ trạng thái tắt
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    
    // 3. Lắng nghe khi app chạy ngầm và người dùng bấm thông báo
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Xử lý mở Google Maps khi bấm thông báo
  void _handleMessage(RemoteMessage message) async {
    // Kiểm tra loại thông báo
    if (message.data['type'] == 'EMERGENCY_PANIC') {
      double lat = double.tryParse(message.data['latitude'].toString()) ?? 0.0;
      double lng = double.tryParse(message.data['longitude'].toString()) ?? 0.0;

      // [SỬA] Link Google Maps chuẩn để mở tọa độ
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
      home: const LoginScreen(),
    );
  }
}