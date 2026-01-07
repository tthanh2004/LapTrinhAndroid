import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../../../common/constants.dart';
import '../../../../services/user_service.dart';
import '../../../../services/auth_service.dart';
import '../auth/login_screen.dart';
import './profile/personal_info_screen.dart';
import './security/verify_pin_screen.dart';

class SettingsTab extends StatefulWidget {
  final int userId; 
  const SettingsTab({super.key, required this.userId});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _gpsTracking = false;
  bool _backgroundMode = false;
  bool _notifications = false;

  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkStatus();
  }

  Future<void> _loadUserData() async {
    final profile = await _userService.getUserProfile(widget.userId);
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    final gps = await Permission.location.isGranted;
    final notif = await Permission.notification.isGranted;
    
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (mounted) {
      setState(() {
        _gpsTracking = gps;
        _notifications = notif;
        _backgroundMode = isRunning;
      });
    }
  }

  Future<void> _toggleBackgroundMode(bool value) async {
    final service = FlutterBackgroundService();
    if (value) {
      await service.startService();
    } else {
      service.invoke("stopService");
    }
    setState(() => _backgroundMode = value);
  }

  Future<void> _togglePermission(Permission permission) async {
    if (!(await permission.isGranted)) {
      final status = await permission.request();
      if (status.isPermanentlyDenied) {
        openAppSettings(); 
      } else if (status.isGranted && permission == Permission.notification) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          _userService.updateFcmToken(widget.userId, token);
        }
      }
    } else {
      openAppSettings();
    }
    await _checkStatus();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout(); 
              
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()), 
                (route) => false,
              );
            },
            child: const Text("Đăng xuất", style: TextStyle(color: kDangerColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30), // Tăng nhẹ padding bottom cho thoáng
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB), // Sử dụng màu phẳng (Solid) theo Figma image_a50fa0.png
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Icon Cài đặt to ở bên trái (Dựa theo ảnh thiết kế cài đặt)
                const Icon(Icons.settings, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cài đặt",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tùy chỉnh ứng dụng",
                        style: TextStyle(
                          color: Colors.blue[100],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Đã xóa phần CircleAvatar và IconButton (hình bút chì)
              ],
            ),
          ),

          // Body List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle("Thông tin cá nhân"),
                Container(
                  decoration: _boxDecoration(),
                  child: _buildTile(
                    icon: Icons.person, 
                    iconColor: kPrimaryColor,
                    bgColor: Colors.blue[50]!,
                    title: "Cập nhật thông tin",
                    subtitle: "Thay đổi tên, email & ảnh đại diện",
                    showArrow: true,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => PersonalInfoScreen(userId: widget.userId))
                      ).then((_) => _loadUserData());
                    },
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("Bảo mật"),
                Container(
                  decoration: _boxDecoration(),
                  child: _buildTile(
                    icon: Icons.lock,
                    iconColor: kPrimaryColor,
                    bgColor: Colors.blue[50]!,
                    title: "Mã PIN",
                    subtitle: "Đổi PIN an toàn & PIN khẩn cấp",
                    showArrow: true,
                    onTap: () {
                      // [CODE CHUẨN] Truyền userId và userName
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => VerifyPinScreen(
                            userId: widget.userId,
                            userName: _userProfile?['fullName'] ?? "User",
                          )
                        )
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("Quyền truy cập"),
                Container(
                  decoration: _boxDecoration(),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.location_on, iconColor: Colors.green, bgColor: Colors.green[50]!,
                        title: "Theo dõi GPS", subtitle: "Luôn bật để gửi vị trí chính xác",
                        value: _gpsTracking,
                        onChanged: (v) => _togglePermission(Permission.location),
                      ),
                      const Divider(height: 1, indent: 60),
                      _buildSwitchTile(
                        icon: Icons.smartphone, iconColor: Colors.purple, bgColor: Colors.purple[50]!,
                        title: "Chạy nền", subtitle: "Cho phép theo dõi khi tắt màn hình",
                        value: _backgroundMode,
                        onChanged: (v) => _toggleBackgroundMode(v), 
                      ),
                      const Divider(height: 1, indent: 60),
                      _buildSwitchTile(
                        icon: Icons.notifications, iconColor: Colors.orange, bgColor: Colors.orange[50]!,
                        title: "Thông báo", subtitle: "Nhận cảnh báo khẩn cấp",
                        value: _notifications,
                        onChanged: (v) => _togglePermission(Permission.notification),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("Tài khoản"),
                Container(
                  decoration: _boxDecoration(),
                  child: ListTile(
                    onTap: _handleLogout,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.logout, color: kDangerColor, size: 20)),
                    title: const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold, color: kDangerColor)),
                    subtitle: const Text("Thoát khỏi tài khoản", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  BoxDecoration _boxDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]);
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)));

  Widget _buildTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required VoidCallback onTap, bool showArrow = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: showArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: iconColor, activeColor: iconColor),
    );
  }
}