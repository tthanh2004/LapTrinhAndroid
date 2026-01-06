import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // [MỚI] Import mở link
import 'firebase_options.dart';

import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/auth/login_screen.dart';
import 'screens/mobile/settings/security/verify_pin_screen.dart';
import 'screens/mobile/settings/security/create_new_pin_screen.dart';
import 'screens/mobile/settings/profile/personal_info_screen.dart';

// [MỚI] Hàm xử lý thông báo khi app đang tắt (Background Handler)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // [MỚI] Khởi tạo môi trường
  WidgetsFlutterBinding.ensureInitialized();

  // Sử dụng DefaultFirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Đăng ký handler chạy ngầm
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      child: const SafeTrekApp(),
    ),
  );
}

// [SỬA] Chuyển thành StatefulWidget để lắng nghe sự kiện
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

  // [MỚI] Cấu hình lắng nghe thông báo
  Future<void> _setupInteractedMessage() async {
    // 1. Xin quyền thông báo (quan trọng cho iOS/Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Xử lý khi App đang tắt mà người dùng bấm vào thông báo
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 3. Xử lý khi App đang chạy ngầm (Background) mà người dùng bấm vào thông báo
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    
    // 4. (Tùy chọn) Xử lý khi App đang mở (Foreground) -> Hiện thông báo popup hoặc xử lý luôn
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
       // Bạn có thể hiện một dialog hoặc snackbar ở đây nếu muốn
       print('Nhận thông báo khi app đang mở: ${message.notification?.title}');
    });
  }

  // [QUAN TRỌNG] Hàm xử lý Logic mở Google Maps
  void _handleMessage(RemoteMessage message) async {
    if (message.data['type'] == 'EMERGENCY_PANIC') {
      // Parse tọa độ
      double lat = double.tryParse(message.data['latitude'].toString()) ?? 0.0;
      double lng = double.tryParse(message.data['longitude'].toString()) ?? 0.0;

      // Tạo link Google Maps trỏ đúng đến tọa độ (geo query)
      final Uri googleUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

      try {
        if (await canLaunchUrl(googleUrl)) {
          // Mở bằng ứng dụng ngoài (Google Maps App)
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
        primaryColor: kPrimaryColor, // Đảm bảo bạn đã định nghĩa kPrimaryColor trong constants.dart
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/profile': (context) => const PersonalInfoScreen(),
        '/verify_pin': (context) => const VerifyPinScreen(),
        '/create_pin': (context) => const CreateNewPinScreen(),
      },
    );
  }
}