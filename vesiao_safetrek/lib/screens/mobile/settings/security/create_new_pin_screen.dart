import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http
import '../../../../common/constants.dart';

// Các màu sắc riêng cho màn hình này
const Color kSafePinBg = Color(0xFFEFF6FF);
const Color kSafePinBorder = Color(0xFFDBEAFE);
const Color kDuressPinBg = Color(0xFFFEF2F2);
const Color kDuressPinBorder = Color(0xFFFEE2E2);

class CreateNewPinScreen extends StatefulWidget {
  final int userId; // [QUAN TRỌNG] Nhận userId để biết update cho ai
  const CreateNewPinScreen({super.key, required this.userId});

  @override
  State<CreateNewPinScreen> createState() => _CreateNewPinScreenState();
}

class _CreateNewPinScreenState extends State<CreateNewPinScreen> {
  // 4 Controller cho 4 ô nhập liệu
  final _safePin = TextEditingController();
  final _confirmSafePin = TextEditingController();
  final _duressPin = TextEditingController();
  final _confirmDuressPin = TextEditingController();

  bool _isButtonEnabled = false;
  bool _isObscure = true;
  bool _isLoading = false; // Trạng thái loading

  // Hàm kiểm tra điều kiện để bật nút Lưu
  void _check() {
    final safe = _safePin.text;
    final confirmSafe = _confirmSafePin.text;
    final duress = _duressPin.text;
    final confirmDuress = _confirmDuressPin.text;

    bool safeFilled = safe.length == 4 && confirmSafe.length == 4;
    bool duressFilled = duress.length == 4 && confirmDuress.length == 4;
    bool safeMatched = safe == confirmSafe;
    bool duressMatched = duress == confirmDuress;
    bool pinsDifferent = safe.isNotEmpty && duress.isNotEmpty && safe != duress;

    setState(() {
      _isButtonEnabled = safeFilled && duressFilled && safeMatched && duressMatched && pinsDifferent;
    });
  }

  // Hàm gọi API cập nhật PIN
  Future<void> _handleUpdatePin() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/update-pins'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'safePin': _safePin.text,
          'duressPin': _duressPin.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đổi mã PIN thành công!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Quay về Settings
      } else {
        // Lỗi từ server
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? "Lỗi cập nhật"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _safePin.addListener(_check);
    _confirmSafePin.addListener(_check);
    _duressPin.addListener(_check);
    _confirmDuressPin.addListener(_check);
  }

  @override
  void dispose() {
    _safePin.dispose();
    _confirmSafePin.dispose();
    _duressPin.dispose();
    _confirmDuressPin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            width: double.infinity,
            color: kPrimaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Hủy", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Đổi mã PIN", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Tạo mã PIN an toàn & khẩn cấp mới", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          // --- BODY ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Phần Mã PIN an toàn
                  _buildPinSection(
                    title: "Mã PIN an toàn mới",
                    description: "Nhập mã PIN này khi bạn đến nơi an toàn",
                    icon: Icons.lock_outline,
                    themeColor: kPrimaryColor,
                    bgColor: kSafePinBg,
                    borderColor: kSafePinBorder,
                    pinController: _safePin,
                    confirmController: _confirmSafePin,
                    pinHint: "4 chữ số",
                    confirmHint: "Nhập lại 4 chữ số",
                  ),
                  const SizedBox(height: 24),

                  // 2. Phần Mã PIN khẩn cấp
                  _buildPinSection(
                    title: "Mã PIN khẩn cấp mới (Duress)",
                    description: "Dùng mã này để kích hoạt cảnh báo ngầm",
                    icon: Icons.warning_amber_rounded,
                    themeColor: kDangerColor,
                    bgColor: kDuressPinBg,
                    borderColor: kDuressPinBorder,
                    pinController: _duressPin,
                    confirmController: _confirmDuressPin,
                    pinLabel: "Mã PIN khẩn cấp",
                    confirmLabel: "Xác nhận PIN khẩn cấp",
                    pinHint: "4 chữ số khác",
                    confirmHint: "Nhập lại 4 chữ số",
                  ),
                  const SizedBox(height: 20),

                  // 3. Nút Ẩn/Hiện mã PIN
                  GestureDetector(
                    onTap: () => setState(() => _isObscure = !_isObscure),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(_isObscure ? "Hiện mã PIN" : "Ẩn mã PIN", style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Lưu ý quan trọng
                  _buildNoteSection(),
                  const SizedBox(height: 30),

                  // 5. Nút Lưu thay đổi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isButtonEnabled && !_isLoading) ? _handleUpdatePin : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS HỖ TRỢ ---
  Widget _buildPinSection({
    required String title, required String description, required IconData icon,
    required Color themeColor, required Color bgColor, required Color borderColor,
    required TextEditingController pinController, required TextEditingController confirmController,
    String pinLabel = "Mã PIN mới", String confirmLabel = "Xác nhận mã PIN",
    required String pinHint, required String confirmHint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: themeColor, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: themeColor, fontWeight: FontWeight.w600, fontSize: 16))]),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: themeColor.withOpacity(0.8), fontSize: 13)),
          const SizedBox(height: 20),
          _buildLabel(pinLabel, themeColor),
          const SizedBox(height: 8),
          _buildPinInput(pinController, pinHint, borderColor),
          const SizedBox(height: 16),
          _buildLabel(confirmLabel, themeColor),
          const SizedBox(height: 8),
          _buildPinInput(confirmController, confirmHint, borderColor),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500));
  }

  Widget _buildPinInput(TextEditingController controller, String hint, Color borderColor) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 4,
      obscureText: _isObscure,
      style: const TextStyle(fontSize: 16, letterSpacing: 2),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 0),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPrimaryColor)),
        counterText: "", contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildNoteSection() {
    const Color noteBg = Color(0xFFFFF7ED);
    const Color noteBorder = Color(0xFFFFEDD5);
    const Color noteText = Color(0xFFC2410C);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: noteBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: noteBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.warning_amber_rounded, color: noteText, size: 20), SizedBox(width: 8), Text("Lưu ý quan trọng", style: TextStyle(color: noteText, fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 12),
          _buildBulletPoint("Hai mã PIN phải khác nhau hoàn toàn", noteText),
          _buildBulletPoint("Không chia sẻ mã PIN với bất kì ai", noteText),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 14))),
        ],
      ),
    );
  }
}