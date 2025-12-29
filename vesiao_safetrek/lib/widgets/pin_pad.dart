import 'package:flutter/material.dart';
import '../common/constants.dart';

class PinPad extends StatefulWidget {
  final Function(String pin) onPinSubmit;

  const PinPad({super.key, required this.onPinSubmit});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String pin = "";
  String errorMessage = "";
  bool isLoading = false;

  void _handlePinInput(String digit) {
    if (isLoading) return;

    if (pin.length < 4) {
      setState(() {
        pin += digit;
        errorMessage = "";
      });

      if (pin.length == 4) {
        setState(() => isLoading = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onPinSubmit(pin);
          setState(() => isLoading = false);
        });
      }
    }
  }

  void _handleDelete() {
    if (pin.isNotEmpty && !isLoading) {
      setState(() => pin = pin.substring(0, pin.length - 1));
    }
  }

  void _handleClear() {
    if (!isLoading) setState(() => pin = "");
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chiều cao màn hình để tính toán không gian hợp lý
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header (Icon khiên + Text)
          Padding(
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 24 : 40),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Xác nhận an toàn",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Nhập mã PIN của bạn",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Phần nội dung chính (Màu trắng)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView( // <--- QUAN TRỌNG: Sửa lỗi Overflow
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Co giãn theo nội dung
                  children: [
                    const SizedBox(height: 10),
                    
                    // 1. Dòng hiển thị PIN (4 chấm tròn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool isFilled = pin.length > index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isFilled ? kPrimaryColor : Colors.grey[100],
                            border: Border.all(
                              color: isFilled ? kPrimaryColor : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: isFilled
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 24), // Tăng khoảng cách chút cho thoáng

                    // 2. Loading Indicator (nếu có)
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),

                    // 3. Bàn phím số
                    SizedBox(
                      width: 320, // Giới hạn chiều rộng để đẹp trên iPad/Tablet
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của GridView
                        crossAxisCount: 3,
                        childAspectRatio: 1.5, // Nút dẹt hơn chút để tiết kiệm chiều cao
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map(
                            (num) => _buildNumBtn(
                              num.toString(),
                              onTap: () => _handlePinInput(num.toString()),
                            ),
                          ),
                          _buildNumBtn("C",
                              isAction: true, fontSize: 18, onTap: _handleClear),
                          _buildNumBtn("0", onTap: () => _handlePinInput("0")),
                          _buildNumBtn("⌫",
                              isAction: true, onTap: _handleDelete),
                        ],
                      ),
                    ),
                    
                    // Thêm khoảng trống dưới cùng để tránh bị che bởi thanh điều hướng Home (trên iPhone X+)
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String text,
      {required VoidCallback onTap, bool isAction = false, double fontSize = 24}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isAction ? FontWeight.normal : FontWeight.w600,
            color: kTextColor,
          ),
        ),
      ),
    );
  }
}