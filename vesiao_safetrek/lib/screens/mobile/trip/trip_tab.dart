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
  // Controller cho ô nhập điểm đến
  final TextEditingController _destController = TextEditingController();
  // [MỚI] Controller cho ô nhập thời gian (Mặc định 15 phút)
  final TextEditingController _durationController = TextEditingController(text: "15");

  // State quản lý hiển thị Modal SOS
  bool _showPanicAlert = false;
  bool _isSending = false;

  @override
  void dispose() {
    _destController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ NÚT HOẢNG LOẠN ---
  Future<void> _handlePanicButton() async {
    setState(() {
      _showPanicAlert = true;
      _isSending = true;
    });

    try {
      final controller = Provider.of<TripController>(context, listen: false);
      
      // 1. Gửi tín hiệu khẩn cấp
      await controller.triggerPanic(widget.userId);

      // 2. Dừng chuyến đi (chuyển sang trạng thái khẩn cấp)
      controller.stopTrip(isSafe: false);

    } catch (_) {
      // Bỏ qua lỗi để UI không bị crash
    } finally {
      if (mounted) setState(() => _isSending = false);

      // 3. Đợi 4 giây hiển thị thông báo rồi đóng Modal
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
    return Scaffold(
      body: Stack(
        children: [
          // Lắng nghe Controller để thay đổi giao diện (Setup vs Active)
          Consumer<TripController>(
            builder: (context, controller, child) {
              return controller.isMonitoring
                  ? _buildActiveView(context, controller)
                  : _buildSetupView(context, controller);
            },
          ),
          
          // Modal SOS đè lên trên cùng nếu được kích hoạt
          if (_showPanicAlert) _buildPanicModal(),
        ],
      ),
    );
  }

  // --- GIAO DIỆN 1: CÀI ĐẶT CHUYẾN ĐI (SETUP) ---
  Widget _buildSetupView(BuildContext context, TripController controller) {
    return Column(
      children: [
        _buildHeader(
          title: "Cài đặt chuyến đi", 
          subtitle: "Thiết lập giám sát an toàn", 
          icon: Icons.shield
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryLight, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.blue.shade200)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.shield, size: 16, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Hệ thống sẽ tự động báo động nếu hết giờ mà bạn chưa xác nhận an toàn.", 
                          style: TextStyle(color: kPrimaryColor, fontSize: 13, height: 1.4)
                        )
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text("Điểm đến (Tùy chọn)", style: TextStyle(color: kSubTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _destController,
                  decoration: InputDecoration(
                    hintText: "Ví dụ: Nhà, Ký túc xá...", 
                    prefixIcon: const Icon(Icons.location_on, size: 20), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text("Thời gian dự kiến (phút)", style: TextStyle(color: kSubTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                
                // [MỚI] Ô nhập thời gian cho phép chỉnh sửa
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    int? mins = int.tryParse(val);
                    if (mins != null && mins > 0) {
                      controller.setDuration(mins); // Cập nhật vào controller
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time, size: 20), 
                    suffixText: "phút", 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                  ),
                ),

                const SizedBox(height: 16),
                const Text("Chọn nhanh:", style: TextStyle(color: kSubTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                
                // Các nút chọn nhanh (Chip)
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 30, 60].map((mins) {
                    final isSelected = controller.selectedMinutes == mins;
                    return ChoiceChip(
                      label: Text("$mins phút"), 
                      selected: isSelected, 
                      onSelected: (_) {
                        controller.setDuration(mins);
                        // Cập nhật ngược lại ô input text
                        _durationController.text = mins.toString();
                        // Ẩn bàn phím nếu đang mở
                        FocusScope.of(context).unfocus();
                      },
                      selectedColor: kPrimaryColor, 
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : kSubTextColor, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      ), 
                      backgroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), 
                        side: BorderSide(color: isSelected ? kPrimaryColor : Colors.grey.shade300)
                      )
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 32),
                
                // Nút Bắt đầu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Gửi thông tin sang Controller để bắt đầu
                      controller.startTrip(
                        userId: widget.userId, 
                        destinationName: _destController.text.isNotEmpty ? _destController.text : null
                      );
                    },
                    icon: const Icon(Icons.shield, size: 20),
                    label: const Text("Bắt đầu giám sát", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),
                
                // Nút SOS đỏ dưới cùng
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _handlePanicButton, 
                    icon: const Icon(Icons.warning_amber_rounded, size: 24), 
                    label: const Text("NÚT HOẢNG LOẠN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDangerColor, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    )
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

  // --- GIAO DIỆN 2: ĐANG GIÁM SÁT (ACTIVE) ---
  Widget _buildActiveView(BuildContext context, TripController controller) {
    return Column(
      children: [
        // [FIX] Header hiển thị đúng điểm đến từ Controller
        _buildHeader(
          title: "Đang giám sát", 
          subtitle: (controller.currentDestination != null && controller.currentDestination!.isNotEmpty) 
              ? "Đến: ${controller.currentDestination}" 
              : "Đang di chuyển", 
          icon: Icons.shield_outlined, 
          showAvatar: true
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Đồng hồ đếm ngược
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vòng tròn nền xám
                    SizedBox(
                      width: 260, height: 260, 
                      child: CircularProgressIndicator(
                        value: 1, 
                        strokeWidth: 12, 
                        color: Colors.grey.shade100
                      )
                    ),
                    // Vòng tròn tiến độ xanh
                    SizedBox(
                      width: 260, height: 260, 
                      child: CircularProgressIndicator(
                        value: controller.progress, 
                        strokeWidth: 12, 
                        color: kPrimaryColor, 
                        strokeCap: StrokeCap.round
                      )
                    ),
                    // Chữ số giờ
                    Column(
                      children: [
                        Text(
                          controller.formattedTime, 
                          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: kPrimaryColor)
                        ), 
                        const Text("còn lại", style: TextStyle(color: Colors.grey, fontSize: 16))
                      ]
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // [MỚI] Các nút gia hạn thời gian
                Text("Cần thêm thời gian?", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => controller.extendTrip(5), 
                      icon: const Icon(Icons.add, size: 18), 
                      label: const Text("+5 Phút"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: const BorderSide(color: kPrimaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => controller.extendTrip(10), 
                      icon: const Icon(Icons.add, size: 18), 
                      label: const Text("+10 Phút"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: const BorderSide(color: kPrimaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                
                // Thông báo trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), 
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: const Color(0xFFDBEAFE))
                  ), 
                  child: Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: kPrimaryColor, size: 20), 
                      SizedBox(width: 12), 
                      Expanded(
                        child: Text(
                          "Chúng tôi đang theo dõi di chuyển của bạn", 
                          style: TextStyle(color: Color(0xFF1E40AF), fontSize: 14)
                        )
                      )
                    ]
                  )
                ),
                
                const SizedBox(height: 24),
                
                // Nút "Tôi đã an toàn" (Màu xanh lá)
                SizedBox(
                  width: double.infinity, height: 56, 
                  child: ElevatedButton.icon(
                    onPressed: () => _openPinPad(context, controller), 
                    icon: const Icon(Icons.check_circle_outline, size: 24), 
                    label: const Text("Tôi đã an toàn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                      elevation: 0
                    )
                  )
                ),
                
                const SizedBox(height: 16),
                
                // Nút "NÚT HOẢNG LOẠN" (Màu đỏ)
                SizedBox(
                  width: double.infinity, height: 56, 
                  child: ElevatedButton.icon(
                    onPressed: _handlePanicButton, 
                    icon: const Icon(Icons.error_outline, size: 24), 
                    label: const Text("NÚT HOẢNG LOẠN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444), 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                      elevation: 0
                    )
                  )
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- CÁC WIDGET PHỤ TRỢ ---

  Widget _buildHeader({required String title, required String subtitle, IconData? icon, bool showAvatar = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24), 
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight, 
          colors: [kPrimaryColor, Color(0xFF1D4ED8)]
        )
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), 
                  if (subtitle.isNotEmpty) 
                    Row(
                      children: [
                        if (showAvatar) const Icon(Icons.location_on, color: Colors.white70, size: 14), 
                        if (showAvatar) const SizedBox(width: 4), 
                        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14))
                      ]
                    )
                ]
              )
            ]
          ), 
          if (showAvatar) 
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
        ]
      )
    );
  }

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
            Align(
              alignment: Alignment.topRight, 
              child: GestureDetector(
                onTap: () => setState(() => _showPanicAlert = false), 
                child: const Icon(Icons.close, color: Colors.black54, size: 24)
              )
            ),
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle), 
              child: _isSending 
                ? const CircularProgressIndicator(color: Colors.red) 
                : const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 60)
            ),
            const SizedBox(height: 24),
            Text(
              _isSending ? "ĐANG GỬI CỨU HỘ..." : "Cảnh báo SOS đã được gửi!", 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF334155))
            ),
            const SizedBox(height: 24),
            if (!_isSending) 
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Column(
                  children: [
                    _buildPanicInfoRow("Cảnh báo khẩn cấp"),
                    _buildPanicInfoRow("Vị trí GPS"),
                    _buildPanicInfoRow("Mức pin điện thoại"),
                    _buildPanicInfoRow("Thời gian cảnh báo"),
                  ]
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), 
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.red, size: 8), 
          const SizedBox(width: 12), 
          Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15))
        ]
      )
    );
  }

  // Hàm mở bàn phím PIN để xác nhận an toàn
  void _openPinPad(BuildContext context, TripController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinPad(
        onPinSubmit: (String inputPin) async {
          // Gọi API verify pin trong controller
          String status = await controller.verifyPin(widget.userId, inputPin);
          
          if (!mounted) return;

          if (status == 'SAFE') {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã xác nhận an toàn!"), backgroundColor: Colors.green));
            controller.stopTrip(isSafe: true);
          } else if (status == 'DURESS') {
            Navigator.pop(context);
            await controller.triggerPanic(widget.userId);
            controller.stopTrip(isSafe: false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Cảnh báo ngầm đã được gửi!"), backgroundColor: Colors.orange));
          } else {
            // Đếm số lần sai
            int currentErrors = controller.incrementPinError();
            Navigator.pop(context);

            if (currentErrors >= 5) {
              await controller.triggerPanic(widget.userId);
              controller.stopTrip(isSafe: false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã xác nhận an toàn! (Tự động)"), backgroundColor: Colors.green));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Mã PIN không đúng! (Lần $currentErrors/5)"), backgroundColor: Colors.red));
              // Mở lại bàn phím sau 500ms
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && controller.isMonitoring) _openPinPad(context, controller);
              });
            }
          }
        },
      ),
    );
  }
}