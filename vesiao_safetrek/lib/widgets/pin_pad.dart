import 'package:flutter/material.dart';
import '../common/constants.dart'; // Chứa SAFE_PIN, DURESS_PIN, kPrimaryColor...

class PinPad extends StatefulWidget {
  final Function(bool isDuress) onPinSubmit;

  const PinPad({super.key, required this.onPinSubmit});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String pin = "";
  String errorMessage = "";

  void _handlePinInput(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
        errorMessage = "";
      });

      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () {
          // So sánh với biến SAFE_PIN, DURESS_PIN từ constants.dart
          if (pin == SAFE_PIN) {
            _handleSuccess(isDuress: false);
          } else if (pin == DURESS_PIN) {
            _handleSuccess(isDuress: true);
          } else {
            _handleError();
          }
        });
      }
    }
  }

  void _handleError() {
    setState(() {
      errorMessage = "Mã PIN không đúng";
      pin = "";
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => errorMessage = "");
    });
  }

  void _handleSuccess({required bool isDuress}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: kSuccessColor, size: 35),
              ),
              const SizedBox(height: 16),
              const Text("Xác nhận thành công", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Bạn đã xác nhận an toàn thành công", style: TextStyle(color: kSubTextColor), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        widget.onPinSubmit(isDuress);
      }
    });
  }

  void _handleDelete() {
    if (pin.isNotEmpty) setState(() => pin = pin.substring(0, pin.length - 1));
  }

  void _handleClear() {
    setState(() => pin = "");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF1D4ED8)], // Gradient Xanh
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.shield, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text("Xác nhận an toàn", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("Nhập mã PIN của bạn", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          // BODY TRẮNG
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Chấm tròn PIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isFilled = pin.length > index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: isFilled ? kPrimaryColor : Colors.grey[100],
                          border: Border.all(
                            color: isFilled ? kPrimaryColor : Colors.grey.shade300,
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: isFilled ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 20,
                    child: Text(errorMessage, style: const TextStyle(color: kDangerColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.lock, size: 18, color: kPrimaryColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Nhập mã PIN an toàn để xác nhận", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 4),
                              Text("Nếu bị ép buộc, hãy nhập mã PIN khẩn cấp để gửi cảnh báo ngầm.", style: TextStyle(color: kSubTextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Numpad
                  SizedBox(
                    width: 320,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => _buildNumBtn(num.toString(), onTap: () => _handlePinInput(num.toString()))),
                        _buildNumBtn("Xóa", isAction: true, fontSize: 14, onTap: _handleClear),
                        _buildNumBtn("0", onTap: () => _handlePinInput("0")),
                        _buildNumBtn("⌫", isAction: true, onTap: _handleDelete),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Demo Text dùng biến từ constants
                  const Text("Demo: Safe=$SAFE_PIN, Duress=$DURESS_PIN", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String text, {required VoidCallback onTap, bool isAction = false, double fontSize = 24}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: isAction ? FontWeight.normal : FontWeight.w600, color: kTextColor),
        ),
      ),
    );
  }
}