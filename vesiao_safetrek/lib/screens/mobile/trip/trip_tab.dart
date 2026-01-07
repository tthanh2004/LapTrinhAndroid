import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/constants.dart';
import '../../../controllers/trip_controller.dart';
import '../../../widgets/pin_pad.dart';

class TripTab extends StatefulWidget {
  final int userId;

  const TripTab({super.key, required this.userId});

  @override
  State<TripTab> createState() => _TripTabState();
}

class _TripTabState extends State<TripTab> {
  final TextEditingController _destController = TextEditingController();

  // State cho hiệu ứng SOS
  bool _showPanicAlert = false;
  bool _isSending = false;

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  // Hàm xử lý nút Panic (Đồng bộ logic hiển thị Modal giống HomeTab)
  Future<void> _handlePanicButton() async {
    // 1. Hiển thị Modal trạng thái đang gửi
    setState(() {
      _showPanicAlert = true;
      _isSending = true;
    });

    try {
      // 2. Gọi Controller để xử lý API (Controller đã lấy GPS thật)
      final controller = Provider.of<TripController>(context, listen: false);
      await controller.triggerPanic(widget.userId);
    } catch (_) {
      // Xử lý lỗi nếu cần
    } finally {
      // 3. Cập nhật trạng thái đã gửi xong
      if (mounted) {
        setState(() => _isSending = false);
      }

      // 4. Đợi 4 giây rồi tự tắt Modal
      Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showPanicAlert = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Stack để đè Modal lên trên giao diện chính
    return Scaffold(
      body: Stack(
        children: [
          // Lớp dưới: Giao diện chính (Consumer)
          Consumer<TripController>(
            builder: (context, controller, child) {
              return controller.isMonitoring
                  ? _buildActiveView(context, controller)
                  : _buildSetupView(context, controller);
            },
          ),

          // Lớp trên: Modal cảnh báo (Chỉ hiện khi _showPanicAlert = true)
          if (_showPanicAlert) _buildPanicModal(),
        ],
      ),
    );
  }

  // --- VIEW 1: CÀI ĐẶT ---
  Widget _buildSetupView(BuildContext context, TripController controller) {
    return Column(
      children: [
        _buildHeader(
            title: "Cài đặt chuyến đi",
            subtitle: "Thiết lập giám sát an toàn",
            icon: Icons.shield),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.shield, size: 16, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "Chúng tôi sẽ theo dõi chuyến đi của bạn. Nếu bạn không xác nhận an toàn trước khi hết giờ, cảnh báo sẽ được gửi tự động.",
                              style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 13,
                                  height: 1.4))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Điểm đến (Tùy chọn)",
                    style: TextStyle(color: kSubTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _destController,
                  decoration: InputDecoration(
                    hintText: "Ví dụ: Nhà, Ký túc xá...",
                    prefixIcon: const Icon(Icons.location_on, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Thời gian dự kiến (phút)",
                    style: TextStyle(color: kSubTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(
                      text: controller.selectedMinutes.toString()),
                  readOnly: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Chọn nhanh:",
                    style: TextStyle(color: kSubTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 30, 60].map((mins) {
                    final isSelected = controller.selectedMinutes == mins;
                    return ChoiceChip(
                      label: Text("$mins phút"),
                      selected: isSelected,
                      onSelected: (_) => controller.setDuration(mins),
                      selectedColor: kPrimaryColor,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : kSubTextColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: isSelected
                                  ? kPrimaryColor
                                  : Colors.grey.shade300)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.startTrip(
                        userId: widget.userId,
                        destinationName: _destController.text.isEmpty
                            ? null
                            : _destController.text,
                      );
                    },
                    icon: const Icon(Icons.shield, size: 20),
                    label: const Text("Bắt đầu giám sát",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // NÚT PANIC
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: kDangerLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: kDangerColor),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "Nút khẩn cấp sẽ gửi cảnh báo ngay lập tức.",
                              style: TextStyle(
                                  color: kDangerColor, fontSize: 13))),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _handlePanicButton, // Gọi hàm mới
                    icon: const Icon(Icons.warning_amber_rounded, size: 24),
                    label: const Text("NÚT HOẢNG LOẠN",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kDangerColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- VIEW 2: ĐANG GIÁM SÁT ---
  Widget _buildActiveView(BuildContext context, TripController controller) {
    return Column(
      children: [
        _buildHeader(
            title: "Đang giám sát",
            subtitle: _destController.text.isNotEmpty
                ? _destController.text
                : "Đang di chuyển",
            icon: Icons.shield_outlined,
            showAvatar: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            color: Colors.grey.shade100)),
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: controller.progress,
                        strokeWidth: 12,
                        color: kPrimaryColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(children: [
                      Text(controller.formattedTime,
                          style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor)),
                      const Text("còn lại",
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ]),
                  ],
                ),
                const SizedBox(height: 40),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE))),
                  child: Row(
                    children: const [
                      Icon(Icons.shield_outlined,
                          color: kPrimaryColor, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              "Chúng tôi đang theo dõi di chuyển của bạn",
                              style: TextStyle(
                                  color: Color(0xFF1E40AF), fontSize: 14))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPinPad(context, controller),
                    icon: const Icon(Icons.check_circle_outline, size: 24),
                    label: const Text("Tôi đã an toàn",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _handlePanicButton, // Gọi hàm mới
                    icon: const Icon(Icons.error_outline, size: 24),
                    label: const Text("NÚT HOẢNG LOẠN",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildHeader(
      {required String title,
      required String subtitle,
      IconData? icon,
      bool showAvatar = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF1D4ED8)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12)
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (showAvatar)
                          const Icon(Icons.location_on,
                              color: Colors.white70, size: 14),
                        if (showAvatar) const SizedBox(width: 4),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (showAvatar)
            Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  // --- WIDGET MODAL PANIC ---
  Widget _buildPanicModal() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
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
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  void _openPinPad(BuildContext context, TripController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinPad(
        onPinSubmit: (String inputPin) async {
          String status = await controller.verifyPin(widget.userId, inputPin);

          if (!mounted) return;

          if (status == 'SAFE') {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("✅ Đã xác nhận an toàn!"),
                backgroundColor: Colors.green));
            controller.stopTrip(isSafe: true);
          } else if (status == 'DURESS') {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("⚠️ Cảnh báo ngầm đã được gửi!"),
                backgroundColor: Colors.orange));
            controller.stopTrip(isSafe: false);
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(status == 'INVALID'
                    ? "❌ Mã PIN không đúng!"
                    : "Lỗi kết nối Server"),
                backgroundColor: Colors.red));
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && controller.isMonitoring)
                _openPinPad(context, controller);
            });
          }
        },
      ),
    );
  }
}