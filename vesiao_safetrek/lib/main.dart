import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/constants.dart';
import 'controllers/trip_controller.dart';
import 'screens/mobile/mobile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripController()),
      ],
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
      home: const MobileScreen(),
    );
  }
}