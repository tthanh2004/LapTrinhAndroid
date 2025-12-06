import 'package:flutter/material.dart';
import '../../common/constants.dart';
import 'home/home_tab.dart';
import 'trip/trip_tab.dart';
class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const TripTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: "Chuyến đi"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Liên lạc"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Cài đặt"),
        ],
      ),
    );
  }
}