import 'package:flutter/material.dart';
import '../../../common/constants.dart';
import '../auth/login_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _gpsTracking = true;
  bool _backgroundMode = true;
  bool _notifications = true;
  final String _userPhone = "0912 345 678";

  // --- XỬ LÝ LOGOUT ---
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng Dialog trước

              // LOGIC ĐĂNG XUẤT:
              // 1. Xóa token/data (Sau này làm)
              // 2. Chuyển hướng về màn hình Login và xóa hết lịch sử cũ
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Xóa sạch stack để không back lại được
              );
            },
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Cài đặt mã PIN",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Safe PIN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock, size: 16, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Mã PIN an toàn",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Nhập mã này khi bạn đã đến nơi an toàn để tắt hẹn giờ",
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: "Nhập 4 chữ số",
                      filled: true,
                      fillColor: Colors.white,
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Duress PIN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: kDangerColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Mã PIN khẩn cấp (Duress PIN)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Nếu bị ép buộc tắt ứng dụng, nhập mã này để gửi cảnh báo ngầm",
                    style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: "Nhập 4 chữ số khác",
                      filled: true,
                      fillColor: Colors.white,
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.red.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.red.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Lưu thay đổi",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Hủy",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Gradient
        Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Column(
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
                      Text(
                        "Tùy chỉnh ứng dụng",
                        style: TextStyle(color: Colors.blue[100], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // User Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Số điện thoại",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _userPhone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle("Bảo mật"),
              Container(
                decoration: _boxDecoration(),
                child: _buildTile(
                  icon: Icons.lock,
                  iconColor: kPrimaryColor,
                  bgColor: Colors.blue[50]!,
                  title: "Mã PIN",
                  subtitle: "Đổi PIN an toàn & PIN khẩn cấp",
                  onTap: _showPinModal,
                  showArrow: true,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Quyền truy cập"),
              Container(
                decoration: _boxDecoration(),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.location_on,
                      iconColor: Colors.green,
                      bgColor: Colors.green[50]!,
                      title: "Theo dõi GPS",
                      subtitle: "Luôn bật để gửi vị trí chính xác",
                      value: _gpsTracking,
                      onChanged: (v) => setState(() => _gpsTracking = v),
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.smartphone,
                      iconColor: Colors.purple,
                      bgColor: Colors.purple[50]!,
                      title: "Chạy nền",
                      subtitle: "Ứng dụng hoạt động khi tắt màn hình",
                      value: _backgroundMode,
                      onChanged: (v) => setState(() => _backgroundMode = v),
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange[50]!,
                      title: "Thông báo",
                      subtitle: "Nhận cảnh báo và nhắc nhở",
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Tài khoản"),
              Container(
                decoration: _boxDecoration(),
                child: ListTile(
                  onTap: _handleLogout, // Gọi hàm logout ở đây
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: kDangerColor,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Đăng xuất",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kDangerColor,
                    ),
                  ),
                  subtitle: const Text(
                    "Thoát khỏi tài khoản",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info & Warning (Giữ nguyên như cũ)
              _buildSectionTitle("Thông tin"),
              Container(
                decoration: _boxDecoration(),
                child: Column(
                  children: [
                    _buildTile(
                      icon: Icons.shield,
                      iconColor: kPrimaryColor,
                      bgColor: Colors.blue[50]!,
                      title: "Hướng dẫn sử dụng",
                      subtitle: "Cách sử dụng SafeTrek",
                      onTap: () {},
                      showArrow: true,
                    ),
                    const Divider(height: 1, indent: 60),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "Phiên bản",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "1.0.0 (Build 100)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[800],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lưu ý quan trọng",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "SafeTrek không thay thế các dịch vụ khẩn cấp (113, 114, 115). Trong tình huống khẩn cấp thực sự, hãy gọi cảnh sát ngay lập tức.",
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---
  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.0,
      ),
    ),
  );
  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: showArrow
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: iconColor,
      ),
    );
  }
}
