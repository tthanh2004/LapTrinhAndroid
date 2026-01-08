import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
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
  // ignore: unused_field
  bool _isLoadingProfile = true;
  
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkStatus();
  }

  // ... (Các hàm _loadUserData, _checkStatus, _toggleBackgroundMode giữ nguyên)

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

  // [CẬP NHẬT QUAN TRỌNG] Hàm xin quyền & Đăng ký FCM Token
  Future<void> _togglePermission(Permission permission) async {
    final status = await permission.status;

    if (!status.isGranted) {
      final result = await permission.request();
      
      if (result.isPermanentlyDenied) {
        openAppSettings(); 
      } 
      // Nếu là quyền thông báo và người dùng đồng ý -> Lấy Token ngay
      else if (result.isGranted && permission == Permission.notification) {
        await _registerPushNotification();
      }
    } else {
      // Nếu đã có quyền rồi mà bấm vào -> Mở cài đặt để tắt
      openAppSettings();
    }
    await _checkStatus();
  }

  // [MỚI] Hàm lấy Token và gửi lên Server
  Future<void> _registerPushNotification() async {
    try {
      // 1. Lấy token từ Firebase
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print("📲 FCM Token mới: $token");
        // 2. Gửi lên server để lưu vào database
        await _userService.updateFcmToken(widget.userId, token);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã bật thông báo thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("❌ Lỗi đăng ký FCM: $e");
    }
  }

  // ... (Phần _handleLogout và build UI giữ nguyên như cũ)
  // Bạn có thể copy lại phần build UI từ câu trả lời trước, nó đã chuẩn Figma rồi.
  
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
    // ... Copy phần build UI chuẩn Figma từ câu trả lời trước dán vào đây ...
    // Để tiết kiệm không gian, tôi chỉ nhắc lại là phần UI bạn đã có là đúng rồi.
    // Quan trọng là logic _togglePermission và _registerPushNotification ở trên.
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB), 
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cài đặt",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tùy chỉnh ứng dụng",
                        style: TextStyle(color: Colors.blue[100], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle("THÔNG TIN CÁ NHÂN"),
                _buildCardGroup([
                  _buildTile(
                    icon: Icons.person_outline, 
                    iconColor: Colors.blue, 
                    bgColor: Colors.blue[50]!,
                    title: "Cập nhật thông tin",
                    subtitle: "Thay đổi tên, email & ảnh đại diện",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalInfoScreen(userId: widget.userId))).then((_) => _loadUserData()),
                  ),
                ]),

                _buildSectionTitle("BẢO MẬT"),
                _buildCardGroup([
                  _buildTile(
                    icon: Icons.lock_outline, 
                    iconColor: Colors.blue, 
                    bgColor: Colors.blue[50]!,
                    title: "Mã PIN",
                    subtitle: "Đổi mã PIN an toàn & khẩn cấp",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyPinScreen(userId: widget.userId, userName: _userProfile?['fullName'] ?? "User"))),
                  ),
                ]),

                _buildSectionTitle("QUYỀN TRUY CẬP"),
                _buildCardGroup([
                  _buildSwitchTile(
                    icon: Icons.location_on_outlined, iconColor: Colors.green, bgColor: Colors.green[50]!,
                    title: "Theo dõi GPS", subtitle: "Luôn bật để gửi vị trí chính xác",
                    value: _gpsTracking,
                    onChanged: (v) => _togglePermission(Permission.location),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildSwitchTile(
                    icon: Icons.smartphone, iconColor: Colors.purple, bgColor: Colors.purple[50]!,
                    title: "Chạy nền", subtitle: "Hoạt động khi tắt màn hình",
                    value: _backgroundMode,
                    onChanged: (v) => _toggleBackgroundMode(v), 
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildSwitchTile(
                    icon: Icons.notifications_none, iconColor: Colors.orange, bgColor: Colors.orange[50]!,
                    title: "Thông báo", subtitle: "Nhận cảnh báo khẩn cấp",
                    value: _notifications,
                    // GỌI HÀM TOGGLE ĐÃ CẬP NHẬT LOGIC
                    onChanged: (v) => _togglePermission(Permission.notification),
                  ),
                ]),

                _buildSectionTitle("TÀI KHOẢN"),
                _buildCardGroup([
                  _buildTile(
                    icon: Icons.logout, iconColor: kDangerColor, bgColor: Colors.red[50]!,
                    title: "Đăng xuất", subtitle: "Thoát khỏi tài khoản",
                    onTap: _handleLogout,
                    isDanger: true,
                  ),
                ]),

                const SizedBox(height: 24),
                // Box Lưu ý
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
                          SizedBox(width: 8),
                          Text("Lưu ý quan trọng", style: TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "SafeTrek không thay thế các dịch vụ khẩn cấp (113, 114, 115).",
                        style: TextStyle(color: Color(0xFF9A3412), fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)));

  Widget _buildTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required VoidCallback onTap, bool isDanger = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDanger ? Colors.red : Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: iconColor, activeTrackColor: iconColor.withOpacity(0.3)),
    );
  }
}