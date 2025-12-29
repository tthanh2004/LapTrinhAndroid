import 'package:flutter/material.dart';
import '../../common/constants.dart';
import 'home/home_tab.dart';
import 'trip/trip_tab.dart';
import 'contacts/contacts_tab.dart';
import 'settings/settings_tab.dart';

class MobileScreen extends StatefulWidget {
  final int userId;

  const MobileScreen({super.key, required this.userId});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  int _currentIndex = 0;

  // 1. Định nghĩa hàm xử lý chuyển Tab
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2. Khai báo danh sách màn hình ngay trong build để dễ truyền callback
    final List<Widget> tabs = [
      // Tab 0: Trang chủ
      HomeTab(
        userId: widget.userId,
        // Callback: Chuyển sang Tab 1 (Chuyến đi)
        onGoToTrip: () => _onTabTapped(1), 
        // Callback: Chuyển sang Tab 2 (Danh bạ)
        onGoToContacts: () => _onTabTapped(2), 
      ),
      
      // Tab 1: Chuyến đi
      const TripTab(),
      
      // Tab 2: Danh bạ
      ContactsTab(userId: widget.userId),
      
      // Tab 3: Cài đặt
      const SettingsTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      // Dùng IndexedStack để giữ trạng thái các màn hình khi chuyển tab
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Gọi hàm chuyển tab khi bấm vào icon
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Thêm activeIcon cho đẹp
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: "Chuyến đi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Liên lạc",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "Cài đặt",
          ),
        ],
      ),
    );
  }
}