import 'package:flutter/material.dart';
import '../common/constants.dart'; 

class PinPad extends StatefulWidget {
  // SỬA: Callback trả về String pin thay vì bool
  final Function(String pin) onPinSubmit; 

  const PinPad({super.key, required this.onPinSubmit});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String pin = "";
  String errorMessage = "";
  bool isLoading = false; // Thêm trạng thái loading để tránh bấm nhiều lần

  void _handlePinInput(String digit) {
    if (isLoading) return; // Đang check thì không cho bấm

    if (pin.length < 4) {
      setState(() {
        pin += digit;
        errorMessage = "";
      });

      if (pin.length == 4) {
        // Đã nhập đủ 4 số -> Gửi ra ngoài cho TripTab xử lý
        setState(() => isLoading = true);
        
        // Delay nhẹ để người dùng thấy số cuối cùng hiện lên
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onPinSubmit(pin);
          // Lưu ý: Không reset pin ngay ở đây, để UI cha quyết định
          setState(() => isLoading = false);
        });
      }
    }
  }

  // Hàm này để cha gọi vào nếu mã sai
  // (Nhưng ở kiến trúc đơn giản này, ta cứ reset pin khi init hoặc để cha rebuild)
  
  void _handleDelete() {
    if (pin.isNotEmpty && !isLoading) setState(() => pin = pin.substring(0, pin.length - 1));
  }

  void _handleClear() {
    if (!isLoading) setState(() => pin = "");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Cao lên chút
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF1D4ED8)], 
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
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
                          border: Border.all(color: isFilled ? kPrimaryColor : Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: isFilled ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Nếu muốn hiển thị lỗi từ cha, bạn có thể truyền tham số error vào
                  // Ở đây làm đơn giản: reset pin khi sai
                  if (isLoading) const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  
                  const Spacer(),
                  SizedBox(
                    width: 320,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.3,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      children: [
                        ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => _buildNumBtn(num.toString(), onTap: () => _handlePinInput(num.toString()))),
                        _buildNumBtn("C", isAction: true, fontSize: 18, onTap: _handleClear),
                        _buildNumBtn("0", onTap: () => _handlePinInput("0")),
                        _buildNumBtn("⌫", isAction: true, onTap: _handleDelete),
                      ],
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

  Widget _buildNumBtn(String text, {required VoidCallback onTap, bool isAction = false, double fontSize = 24}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: isAction ? FontWeight.normal : FontWeight.w600, color: kTextColor)),
      ),
    );
  }
}