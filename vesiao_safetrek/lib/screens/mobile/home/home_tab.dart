import 'dart:async';
import 'package:flutter/material.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onGoToTripSetup;
  final VoidCallback? onGoToContacts;

  const HomeTab({
    super.key,
    this.onGoToTripSetup,
    this.onGoToContacts,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showPanicAlert = false;
  bool _isPressing = false;

  void _handlePanicButton() {
    setState(() { _showPanicAlert = true; });
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() { _showPanicAlert = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // NỀN GRADIENT
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
                  // --- HEADER (Cố định) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, color: Colors.white, size: 40),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("SafeTrek", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text("Vệ Sĩ Ảo của bạn", style: TextStyle(color: Colors.blue[100], fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- CONTENT (Sửa lỗi Overflow: Cho phép cuộn) ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Status Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              margin: const EdgeInsets.only(bottom: 30),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      const Text("Bạn đang an toàn", style: TextStyle(color: Colors.white, fontSize: 18)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Sẵn sàng bảo vệ bạn 24/7", style: TextStyle(color: Colors.blue[100], fontSize: 14), textAlign: TextAlign.center),
                                ],
                              ),
                            ),

                            // LARGE SOS BUTTON
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isPressing = true),
                              onTapUp: (_) { setState(() => _isPressing = false); _handlePanicButton(); },
                              onTapCancel: () => setState(() => _isPressing = false),
                              child: AnimatedScale(
                                scale: _isPressing ? 0.95 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFDC2626),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10))],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.white, size: 90),
                                      const SizedBox(height: 10),
                                      const Text("SOS", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text("Nhấn để cảnh báo", style: TextStyle(color: Colors.red[100], fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Info Text Box
                            Container(
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
                                  Icon(Icons.info_outline, size: 16, color: Colors.red[100]),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Nút SOS sẽ gửi cảnh báo khẩn cấp ngay lập tức đến tất cả danh bạ khẩn cấp của bạn.", style: TextStyle(color: Colors.red[100], fontSize: 13))),
                                ],
                              ),
                            ),

                            // Action Buttons
                            _buildActionButton(icon: Icons.location_on, text: "Cài đặt chuyến đi", onTap: widget.onGoToTripSetup ?? () {}),
                            const SizedBox(height: 16),
                            _buildActionButton(icon: Icons.people, text: "Quản lý danh bạ khẩn cấp", onTap: widget.onGoToContacts ?? () {}),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PANIC ALERT MODAL
          if (_showPanicAlert)
            Container(
              color: Colors.black.withOpacity(0.7),
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80, margin: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                      child: const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
                    ),
                    const Text("Cảnh báo SOS đã được gửi!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                      child: Column(children: [
                        _buildInfoItem("Cảnh báo khẩn cấp"),
                        _buildInfoItem("Vị trí GPS chính xác"),
                        _buildInfoItem("Mức pin điện thoại"),
                        _buildInfoItem("Thời gian cảnh báo"),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(12), elevation: 2,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Text(text, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF374151), fontSize: 14)),
      ]),
    );
  }
}