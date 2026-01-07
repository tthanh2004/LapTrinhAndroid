import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../common/constants.dart';
import '../../controllers/trip_controller.dart'; 
import 'home/home_tab.dart';
import 'trip/trip_tab.dart';
import 'contacts/contacts_tab.dart';
import 'settings/settings_tab.dart';
import '../../widgets/triple_tap_wrapper.dart';

class MobileScreen extends StatefulWidget {
  final int userId;

  const MobileScreen({super.key, required this.userId});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa danh sách các Tab
    final List<Widget> tabs = [
      HomeTab(
        userId: widget.userId,
        onGoToTrip: () => _onTabTapped(1), 
        onGoToContacts: () => _onTabTapped(2), 
      ),
      TripTab(userId: widget.userId), 
      ContactsTab(userId: widget.userId),
      SettingsTab(userId: widget.userId), 
    ];

    // 1. Bọc ngoài cùng bằng TripleTapWrapper để nhận diện gõ 3 lần toàn màn hình
    return TripleTapWrapper(
      userId: widget.userId,
      child: Consumer<TripController>(
        builder: (context, tripController, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
            // 2. NẾU ĐANG GIÁM SÁT THÌ ẨN THANH ĐIỀU HƯỚNG (Gán null)
            bottomNavigationBar: tripController.isMonitoring 
              ? null 
              : BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: kPrimaryColor,
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: true,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
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
        },
      ),
    );
  }
}