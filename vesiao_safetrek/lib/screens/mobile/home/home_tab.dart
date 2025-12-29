import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../common/constants.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onGoToTripSetup;
  final VoidCallback? onGoToContacts;
  final int userId;

  const HomeTab({
    super.key,
    this.onGoToTripSetup,
    this.onGoToContacts,
    required this.userId,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showPanicAlert = false;
  bool _isPressing = false;
  bool _isSending = false;

  Future<void> _handlePanicButton() async {
    setState(() {
      _showPanicAlert = true;
      _isSending = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/emergency/panic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'lat': position.latitude,
          'lng': position.longitude,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint("✅ SOS Sent: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      debugPrint("❌ SOS Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() { _showPanicAlert = false; });
      });
    }
  }

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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                          _buildActionButton(
                              icon: Icons.location_on,
                              text: "Cài đặt chuyến đi",
                              onTap: widget.onGoToTripSetup ?? () {}),
                          const SizedBox(height: 16),
                          _buildActionButton(
                              icon: Icons.people,
                              text: "Quản lý danh bạ khẩn cấp",
                              onTap: widget.onGoToContacts ?? () {}),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Sửa lỗi padding null ở đây
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SafeTrek",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text("Vệ Sĩ Ảo của bạn",
                  style: TextStyle(color: Colors.blue[100], fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text("Bạn đang an toàn",
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
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
        scale: _isPressing ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFDC2626),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(_isPressing ? 0.6 : 0.3),
                  blurRadius: 40,
                  spreadRadius: 10)
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error_outline, color: Colors.white, size: 90),
              SizedBox(height: 10),
              Text("SOS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
              Text("Nhấn để cảnh báo",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTextBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          const Expanded(
              child: Text(
                  "Nút SOS sẽ gửi cảnh báo khẩn cấp ngay lập tức đến tất cả danh bạ khẩn cấp của bạn.",
                  style: TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Text(text,
                  style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanicModal() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isSending
                ? const CircularProgressIndicator(color: Colors.red)
                : const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              _isSending ? "ĐANG GỬI CỨU HỘ..." : "ĐÃ GỬI CẢNH BÁO SOS!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
                "Vị trí GPS và thông tin của bạn đã được gửi tới người thân.",
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}