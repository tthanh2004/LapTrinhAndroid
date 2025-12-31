import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Core
import 'package:firebase_auth/firebase_auth.dart';

// 2. Import file cấu hình Firebase (File này tự sinh ra khi bạn cài firebase)
import 'firebase_options.dart'; 

import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/auth/login_screen.dart';
import 'screens/mobile/settings/security/verify_pin_screen.dart';
import 'screens/mobile/settings/security/create_new_pin_screen.dart';
import 'screens/mobile/settings/profile/personal_info_screen.dart';
import 'widgets/emergency_detector.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// 3. Chuyển main thành hàm async để đợi Firebase khởi tạo
void main() async {
  // Đảm bảo Flutter Binding được khởi tạo trước khi gọi code bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized(); 

  // 4. Khởi tạo Firebase (SỬA LỖI HÌNH SỐ 3 CỦA BẠN)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      child: const SafeTrekApp(),
    ),
  );
}

class SafeTrekApp extends StatelessWidget {
  const SafeTrekApp({super.key});

  Future<void> _handleEmergency() async {
    print("!!! PHÁT HIỆN KHẨN CẤP !!!");

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text("🆘 ĐANG GỬI TÍN HIỆU KHẨN CẤP!"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? "Anonymous";

      // 5. Sửa lỗi Geolocator deprecated (SỬA LỖI HÌNH SỐ 2)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print("SOS Data -> User: $userId | Lat: ${position.latitude} | Long: ${position.longitude}");

      // Code gửi lên Firestore (nếu có)
      // await FirebaseFirestore.instance.collection('sos').add({...});

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("✅ Đã lấy tọa độ thành công!")),
      );

    } catch (e) {
      print("Lỗi SOS: $e");
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmergencyDetector(
      onEmergencyTriggered: _handleEmergency,
      child: MaterialApp(
        title: 'SafeTrek',
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: kPrimaryColor,
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
      ),
    );
  }
}