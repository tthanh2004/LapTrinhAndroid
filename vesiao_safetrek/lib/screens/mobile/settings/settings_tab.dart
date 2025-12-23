import 'package:flutter/material.dart';
import '../../../common/constants.dart';
import '../auth/login_screen.dart';
// Import các màn hình cần điều hướng đến
import './profile/personal_info_screen.dart';
import './security/verify_pin_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _gpsTracking = true;
  bool _backgroundMode = true;
  bool _notifications = true;

  // Xử lý đăng xuất
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng Dialog
              // Quay về màn Login và xóa lịch sử
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()), 
                (route) => false
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
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Cài đặt", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("Tùy chỉnh ứng dụng", style: TextStyle(color: Colors.blue[100], fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          // Body List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // === SECTION 1: THÔNG TIN CÁ NHÂN ===
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
                    // Điều hướng sang màn hình Profile
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // === SECTION 2: BẢO MẬT ===
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
                    // Điều hướng sang màn hình Verify PIN
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VerifyPinScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // === SECTION 3: QUYỀN TRUY CẬP ===
                _buildSectionTitle("Quyền truy cập"),
                Container(
                  decoration: _boxDecoration(),
                  child: Column(
                    children: [
                      _buildSwitchTile(icon: Icons.location_on, iconColor: Colors.green, bgColor: Colors.green[50]!, title: "Theo dõi GPS", subtitle: "Luôn bật để gửi vị trí chính xác", value: _gpsTracking, onChanged: (v) => setState(() => _gpsTracking = v)),
                      const Divider(height: 1, indent: 60),
                      _buildSwitchTile(icon: Icons.smartphone, iconColor: Colors.purple, bgColor: Colors.purple[50]!, title: "Chạy nền", subtitle: "Ứng dụng hoạt động khi tắt màn hình", value: _backgroundMode, onChanged: (v) => setState(() => _backgroundMode = v)),
                      const Divider(height: 1, indent: 60),
                      _buildSwitchTile(icon: Icons.notifications, iconColor: Colors.orange, bgColor: Colors.orange[50]!, title: "Thông báo", subtitle: "Nhận cảnh báo và nhắc nhở", value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // === SECTION 4: TÀI KHOẢN ===
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
                // Cảnh báo quan trọng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[800], size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text("SafeTrek không thay thế các dịch vụ khẩn cấp (113, 114, 115).", style: TextStyle(color: Colors.orange[800], fontSize: 13))),
                    ],
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
      trailing: Switch(value: value, onChanged: onChanged, activeColor: iconColor),
    );
  }
}