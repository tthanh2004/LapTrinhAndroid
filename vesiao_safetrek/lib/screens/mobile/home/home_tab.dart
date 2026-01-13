import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 

import '../../../../common/constants.dart';
import '../../../../services/emergency_service.dart';
// Import FcmService để khởi tạo nhận tin nhắn
import '../../../../services/fcm_service.dart'; 
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
  // --- STATE ---
  bool _showPanicAlert = false;
  bool _isPressing = false; 
  bool _isSending = false;
  int _unreadCount = 0;

  // --- SERVICES ---
  // Đã xóa _userService vì FcmService đã lo việc update token
  final EmergencyService _emergencyService = EmergencyService();

  @override
  void initState() {
    super.initState();
    
    // [FIX] Khởi tạo FCM Service đúng chỗ
    FcmService().init(widget.userId);
    
    // Lấy số lượng thông báo
    _fetchUnreadCount();
  }

  // Lấy số lượng thông báo chưa đọc
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

  // Xử lý nút SOS
  Future<void> _handlePanicButton() async {
    setState(() {
      _showPanicAlert = true;
      _isSending = true;
    });

    try {
      await _emergencyService.sendEmergencyAlert(widget.userId);
    } catch (e) {
      print("Lỗi gửi SOS: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showPanicAlert = false);
      });
    }
  }

  void _navigateToNotification() async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => NotificationScreen(userId: widget.userId))
    );
    _fetchUnreadCount(); 
  }

  // --- UI COMPONENTS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity, 
            height: double.infinity,
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
                          const SizedBox(height: 30),
                          _buildSosButton(),
                          const SizedBox(height: 40),
                          _buildInfoTextBox(),
                          _buildActionButton(
                            icon: Icons.location_on, 
                            text: "Cài đặt chuyến đi", 
                            onTap: widget.onGoToTrip
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            icon: Icons.people, 
                            text: "Quản lý danh bạ khẩn cấp", 
                            onTap: widget.onGoToContacts
                          ),
                          const SizedBox(height: 40),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
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
            onTap: _navigateToNotification,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8), 
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), 
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28)
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: -2, top: -2, 
                    child: Container(
                      padding: const EdgeInsets.all(4), 
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), 
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20), 
                      child: Text(
                        _unreadCount > 9 ? "9+" : "$_unreadCount", 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), 
                        textAlign: TextAlign.center
                      )
                    )
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.white.withOpacity(0.2))
      ), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            width: 10, height: 10, 
            decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF4ADE80), blurRadius: 6)])
          ), 
          const SizedBox(width: 10), 
          const Text("Hệ thống đang hoạt động", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))
        ]
      )
    );
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressing = true),
      onTapUp: (_) { 
        setState(() => _isPressing = false); 
        _handlePanicButton(); 
      },
      onTapCancel: () => setState(() => _isPressing = false),
      child: AnimatedScale(
        scale: _isPressing ? 0.95 : 1.0, 
        duration: const Duration(milliseconds: 100), 
        child: Container(
          width: 220, height: 220, 
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            color: const Color(0xFFDC2626), 
            gradient: const RadialGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 10)),
              BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 60, spreadRadius: -10),
            ]
          ), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: const [
              Icon(Icons.touch_app, color: Colors.white70, size: 40),
              SizedBox(height: 4),
              Text("SOS", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2)), 
              Text("Nhấn để cầu cứu", style: TextStyle(color: Colors.white70, fontSize: 14))
            ]
          )
        )
      ),
    );
  }

  Widget _buildInfoTextBox() { 
    return Container(
      padding: const EdgeInsets.all(16), 
      margin: const EdgeInsets.only(bottom: 24), 
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(12), 
      ), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: const [
          Icon(Icons.info_outline, size: 20, color: Colors.white70), 
          SizedBox(width: 12), 
          Expanded(child: Text("Nút SOS sẽ gửi vị trí và mức pin hiện tại của bạn đến tất cả người bảo hộ.", style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)))
        ]
      )
    ); 
  }

  Widget _buildActionButton({required IconData icon, required String text, required VoidCallback onTap}) { 
    return Material(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(16), 
      elevation: 4, 
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(16), 
        child: Container(
          width: double.infinity, 
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20), 
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 24)
              ),
              const SizedBox(width: 16), 
              Text(text, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            ]
          )
        )
      )
    ); 
  }

  Widget _buildPanicModal() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isSending 
              ? const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 4))
              : const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 70),
            const SizedBox(height: 24),
            Text(
              _isSending ? "ĐANG GỬI CỨU HỘ..." : "Đã gửi cảnh báo!", 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
            ),
            const SizedBox(height: 12),
            Text(
              _isSending ? "Vui lòng giữ kết nối mạng và GPS" : "Người bảo hộ đã nhận được vị trí của bạn.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            if (!_isSending) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showPanicAlert = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0
                  ),
                  child: const Text("Đóng"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}