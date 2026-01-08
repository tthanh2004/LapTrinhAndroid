import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart'; // [MỚI]
import '../../../../common/constants.dart';
import '../../../../services/user_service.dart'; // [MỚI]
import 'notification_screen.dart';

class HomeTab extends StatefulWidget {
  final int userId;
  final VoidCallback onGoToTrip;
  final VoidCallback onGoToContacts;

  const HomeTab({
    super.key,
    required this.userId,
    required this.onGoToTrip,
    required this.onGoToContacts,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showPanicAlert = false;
  bool _isPressing = false;
  bool _isSending = false;
  
  int _unreadCount = 0;
  Timer? _timer;
  
  final UserService _userService = UserService(); // [MỚI]

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _checkAndRegisterFCM(); // [MỚI] Tự động đăng ký Token khi vào Home
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _fetchUnreadCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // [MỚI] Hàm kiểm tra và cập nhật FCM Token tự động
  Future<void> _checkAndRegisterFCM() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          print("🔄 Auto-update FCM: $token");
          await _userService.updateFcmToken(widget.userId, token);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/emergency/notifications/unread/${widget.userId}'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _unreadCount = data['count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _handlePanicButton() async {
    setState(() { _showPanicAlert = true; _isSending = true; });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      await http.post(
        Uri.parse('${Constants.baseUrl}/emergency/panic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId, 'lat': position.latitude, 'lng': position.longitude}),
      );
    } catch (_) {} 
    finally {
      if (mounted) setState(() => _isSending = false);
      Timer(const Duration(seconds: 4), () { if (mounted) setState(() { _showPanicAlert = false; }); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildStatusCard(),
                          const SizedBox(height: 20),
                          _buildSosButton(),
                          const SizedBox(height: 30),
                          _buildInfoTextBox(),
                          _buildActionButton(icon: Icons.location_on, text: "Cài đặt chuyến đi", onTap: widget.onGoToTrip),
                          const SizedBox(height: 16),
                          _buildActionButton(icon: Icons.people, text: "Quản lý danh bạ khẩn cấp", onTap: widget.onGoToContacts),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showPanicAlert) _buildPanicModal(),
        ],
      ),
    );
  }

  // ... (Các widget _buildHeader, _buildStatusCard, _buildSosButton, _buildInfoTextBox, _buildActionButton giữ nguyên)
  // Vui lòng copy lại từ code cũ vì không thay đổi logic

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("SafeTrek", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Vệ Sĩ Ảo của bạn", style: TextStyle(color: Colors.blue[100], fontSize: 14)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen(userId: widget.userId)));
              _fetchUnreadCount();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28)),
                if (_unreadCount > 0)
                  Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text(_unreadCount > 9 ? "9+" : "$_unreadCount", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)), const SizedBox(width: 8), const Text("Bạn đang an toàn", style: TextStyle(color: Colors.white, fontSize: 18))]));
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressing = true),
      onTapUp: (_) { setState(() => _isPressing = false); _handlePanicButton(); },
      onTapCancel: () => setState(() => _isPressing = false),
      child: AnimatedScale(scale: _isPressing ? 0.90 : 1.0, duration: const Duration(milliseconds: 100), child: Container(width: 240, height: 240, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFDC2626), boxShadow: [BoxShadow(color: Colors.red.withOpacity(_isPressing ? 0.6 : 0.3), blurRadius: 40, spreadRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.error_outline, color: Colors.white, size: 90), SizedBox(height: 10), Text("SOS", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)), Text("Nhấn để cảnh báo", style: TextStyle(color: Colors.white70, fontSize: 14))]))),
    );
  }

  Widget _buildInfoTextBox() { return Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFF7F1D1D).withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Icon(Icons.info_outline, size: 16, color: Colors.white70), SizedBox(width: 8), Expanded(child: Text("Nút SOS sẽ gửi cảnh báo khẩn cấp ngay lập tức đến tất cả danh bạ khẩn cấp của bạn.", style: TextStyle(color: Colors.white70, fontSize: 13)))])); }
  Widget _buildActionButton({required IconData icon, required String text, required VoidCallback onTap}) { return Material(color: Colors.white, borderRadius: BorderRadius.circular(12), elevation: 2, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xFF1D4ED8), size: 20), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 15, fontWeight: FontWeight.w600))])))); }

  Widget _buildPanicModal() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(alignment: Alignment.topRight, child: GestureDetector(onTap: () => setState(() => _showPanicAlert = false), child: const Icon(Icons.close, color: Colors.black54, size: 24))),
            Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle), child: _isSending ? const CircularProgressIndicator(color: Colors.red) : const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 60)),
            const SizedBox(height: 24),
            Text(_isSending ? "ĐANG GỬI CỨU HỘ..." : "Cảnh báo SOS đã được gửi!", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 24),
            if (!_isSending) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _buildPanicInfoRow("Cảnh báo khẩn cấp"),
                _buildPanicInfoRow("Vị trí GPS"),
                _buildPanicInfoRow("Mức pin điện thoại"),
                _buildPanicInfoRow("Thời gian cảnh báo"),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicInfoRow(String text) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [const Icon(Icons.circle, color: Colors.red, size: 8), const SizedBox(width: 12), Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15))]));
  }
}