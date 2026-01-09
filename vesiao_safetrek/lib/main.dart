import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/auth/login_screen.dart';
import 'screens/mobile/settings/security/verify_pin_screen.dart';
import 'screens/mobile/settings/security/create_new_pin_screen.dart';
import 'screens/mobile/settings/profile/personal_info_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripController())],
      // Truyền màn hình khởi động vào App
      child: SafeTrekApp(initialScreen: initialScreen),
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
      routes: {
        '/': (context) => const LoginScreen(),
        '/profile': (context) => const PersonalInfoScreen(),
        '/verify_pin': (context) => const VerifyPinScreen(),
        '/create_pin': (context) => const CreateNewPinScreen(),
      },
    );
  }
}