import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/constants.dart';
import 'controllers/trip_controller.dart';

// --- IMPORT CÁC MÀN HÌNH ---
// Kiểm tra lại đường dẫn import cho đúng với thư mục máy bạn
import 'screens/mobile/auth/login_screen.dart';
import 'screens/mobile/mobile_screen.dart';
import 'screens/mobile/settings/security/verify_pin_screen.dart';
import 'screens/mobile/settings/security/create_new_pin_screen.dart';
import 'screens/mobile/settings/profile/personal_info_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      child: const SafeTrekApp(),
    ),
  );
}

class SafeTrekApp extends StatelessWidget {
  const SafeTrekApp({super.key});

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
      initialRoute: '/', 
      
      // Bản đồ định tuyến
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const MobileScreen(), // Đây là màn hình chứa BottomBar
        '/profile': (context) => const PersonalInfoScreen(),
        '/verify_pin': (context) => const VerifyPinScreen(),
        '/create_pin': (context) => const CreateNewPinScreen(),
      },
    );
  }
}