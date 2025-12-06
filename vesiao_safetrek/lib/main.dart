import 'package:flutter/material.dart';
import 'common/constants.dart';
import 'screens/mobile/mobile_screen.dart';

void main() {
  runApp(
    const SafeTrekApp(),
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
      home: const MobileScreen(),
    );
  }
}