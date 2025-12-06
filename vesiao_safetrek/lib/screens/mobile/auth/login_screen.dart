import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/constants.dart';
import '../mobile_screen.dart'; // Import màn hình chính để chuyển trang khi login thành công

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Quản lý trạng thái: false = Nhập SĐT, true = Nhập OTP
  bool _showOTP = false;
  final TextEditingController _phoneController = TextEditingController();

  // Xử lý khi nhấn "Tiếp tục"
  void _handlePhoneSubmit() {
    if (_phoneController.text.length >= 10) {
      setState(() {
        _showOTP = true;
      });
    }
  }

  // Xử lý khi đăng nhập thành công
  void _onLoginSuccess() {
    // Chuyển sang màn hình chính (MobileScreen) và xóa lịch sử back
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MobileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nếu showOTP = true thì hiện màn hình OTP, ngược lại hiện màn hình nhập SĐT
    if (_showOTP) {
      return OTPVerificationView(
        phoneNumber: _phoneController.text,
        onVerifySuccess: _onLoginSuccess,
        onBack: () => setState(() => _showOTP = false),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Blue 600-700
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Header
              const SizedBox(height: 80),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                "SafeTrek",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Vệ Sĩ Ảo Của Bạn",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Form Sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Nhập số điện thoại để tiếp tục",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "Số điện thoại",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: "0912345678",
                            counterText: "", // Ẩn bộ đếm ký tự
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Why Phone Number Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(
                                Icons.mail_outline,
                                size: 18,
                                color: kPrimaryColor,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tại sao dùng số điện thoại?",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Người thân dễ nhận biết khi nhận cảnh báo: \"SĐT 09xx đang gặp nguy hiểm\"",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handlePhoneSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Tiếp tục",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "hoặc",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Social Buttons
                        _buildSocialButton(
                          "Đăng nhập bằng Google",
                          Icons.g_mobiledata,
                        ), // Dùng icon tạm
                        const SizedBox(height: 12),
                        _buildSocialButton("Đăng nhập bằng Apple", Icons.apple),

                        const SizedBox(height: 30),

                        // Terms
                        const Center(
                          child: Text.rich(
                            TextSpan(
                              text: "Bằng việc đăng nhập, bạn đồng ý với ",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              children: [
                                TextSpan(
                                  text: "Điều khoản sử dụng",
                                  style: TextStyle(
                                    color: kPrimaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: " và "),
                                TextSpan(
                                  text: "Chính sách bảo mật",
                                  style: TextStyle(
                                    color: kPrimaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.black, size: 24),
        label: Text(
          text,
          style: const TextStyle(color: kTextColor, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// --- OTP VIEW (Widget con) ---
class OTPVerificationView extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerifySuccess;
  final VoidCallback onBack;

  const OTPVerificationView({
    super.key,
    required this.phoneNumber,
    required this.onVerifySuccess,
    required this.onBack,
  });

  @override
  State<OTPVerificationView> createState() => _OTPVerificationViewState();
}

class _OTPVerificationViewState extends State<OTPVerificationView> {
  // List chứa 6 controller cho 6 ô nhập
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Nếu nhập số -> Chuyển sang ô tiếp theo
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Nếu là ô cuối cùng -> Kiểm tra OTP
        _verifyOtp();
      }
    } else {
      // Nếu xóa -> Quay lại ô trước
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyOtp() {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6) {
      // Giả lập verify thành công sau 0.5s
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onVerifySuccess();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 80),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phonelink_lock,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Xác thực OTP",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Mã xác thực đã được gửi đến\n${widget.phoneNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),

              // White Sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Nhập mã OTP",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Vui lòng nhập mã 6 chữ số",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // OTP Input Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 45,
                            height: 55,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              onChanged: (val) => _onOtpChanged(val, index),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: kPrimaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Resend Text
                      if (_resendTimer > 0)
                        Text(
                          "Gửi lại sau ${_resendTimer}s",
                          style: const TextStyle(color: Colors.grey),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            setState(() => _resendTimer = 60);
                            _startTimer();
                          },
                          child: const Text(
                            "Gửi lại mã",
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                      // Demo info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE047)),
                        ), // Yellow 50
                        child: const Text(
                          "Demo: Nhập mã 123456 để tiếp tục",
                          style: TextStyle(
                            color: Color(0xFF854D0E),
                            fontSize: 13,
                          ),
                        ), // Yellow 800
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: widget.onBack,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Đổi số điện thoại",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
