import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/auth/login_screen.dart';
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

  // 3. Khởi tạo cấu hình chạy nền
  await initializeBackgroundService();

  // 4. Xin quyền khởi động
  await _requestInitialPermissions();

  // 5. Kiểm tra trạng thái đăng nhập
  final authService = AuthService();
  final loginInfo = await authService.getLoginInfo();
  
  Widget initialScreen = const LoginScreen();

  if (loginInfo != null && loginInfo['userId'] != null) {
    print("User đã đăng nhập: ID ${loginInfo['userId']}");
    initialScreen = MobileScreen(userId: loginInfo['userId']);
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      child: SafeTrekApp(initialScreen: initialScreen),
    ),
  );
}

Future<void> _requestInitialPermissions() async {
  await Permission.location.request();
  await Permission.notification.request();
}

class SafeTrekApp extends StatefulWidget {
  final Widget? initialScreen;
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
    
    // Xin quyền lại một lần nữa cho chắc chắn
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Xử lý khi click vào thông báo từ trạng thái Terminated (Tắt hẳn)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    
    // Xử lý khi click vào thông báo từ trạng thái Background (Chạy ngầm)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Xử lý logic khi bấm vào thông báo
  void _handleMessage(RemoteMessage message) async {
    // Nếu là thông báo khẩn cấp -> Mở Google Maps
    if (message.data['type'] == 'EMERGENCY_PANIC') {
      double lat = double.tryParse(message.data['lat']?.toString() ?? message.data['latitude']?.toString() ?? '') ?? 0.0;
      double lng = double.tryParse(message.data['lng']?.toString() ?? message.data['longitude']?.toString() ?? '') ?? 0.0;

      if (lat != 0.0 && lng != 0.0) {
        // [FIX] URL chuẩn để mở vị trí và đặt marker
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
      home: widget.initialScreen ?? const LoginScreen(),
    );
  }
}