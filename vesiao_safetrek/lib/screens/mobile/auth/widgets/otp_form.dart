import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../common/constants.dart';
import '../utils/auth_colors.dart';

class OtpForm extends StatefulWidget {
  final String contactInfo;
  final bool isEmailMode;
  final String? verificationId; // ID xác thực từ Firebase (chỉ dùng cho SĐT)
  final Function(int) onVerifySuccess;
  final VoidCallback onBack;

  const OtpForm({
    super.key,
    required this.contactInfo,
    required this.isEmailMode,
    this.verificationId,
    required this.onVerifySuccess,
    required this.onBack,
  });

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendTimer = 60;
  Timer? _timer;
  bool _isVerifying = false; // Trạng thái đang xác thực

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Nếu là Email -> Tự động gọi API gửi mã khi mở màn hình
    if (widget.isEmailMode) {
      _sendOtpToEmail();
    }
  }

  // --- API: GỬI OTP EMAIL ---
  Future<void> _sendOtpToEmail() async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.contactInfo}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Đã gửi Email OTP");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Mã OTP đã được gửi đến email"),
                backgroundColor: Colors.green),
          );
        }
      } else {
        debugPrint("❌ Lỗi gửi OTP: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Lỗi kết nối: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Tự động submit khi nhập đủ 6 số
        _handleVerify();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // --- LOGIC XÁC THỰC CHÍNH ---
  void _handleVerify() async {
    String otpCode = _controllers.map((e) => e.text).join();
    if (otpCode.length < 6) return;

    setState(() => _isVerifying = true);

    if (widget.isEmailMode) {
      await _verifyEmailOtp(otpCode);
    } else {
      await _verifyPhoneOtp(otpCode);
    }

    if (mounted) setState(() => _isVerifying = false);
  }

  // 1. Xác thực Email
  Future<void> _verifyEmailOtp(String code) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.contactInfo,
          'code': code,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int userId = data['userId'];
        widget.onVerifySuccess(userId);
      } else {
        _showError("Mã OTP không đúng hoặc đã hết hạn");
      }
    } catch (e) {
      _showError("Lỗi kết nối Server");
    }
  }

  // 2. Xác thực Số điện thoại
  Future<void> _verifyPhoneOtp(String code) async {
    try {
      // a. Tạo credential từ mã OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId!,
        smsCode: code,
      );

      // b. Đăng nhập Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      User? user = userCredential.user;

      if (user != null) {
        // c. Lấy ID Token từ Firebase
        String? token = await user.getIdToken();
        
        // d. Gửi Token về Backend NestJS để tạo/lấy User
        await _callBackendPhoneLogin(token!);
      }
    } catch (e) {
      _showError("Mã OTP không đúng. Vui lòng thử lại.");
      print("Firebase Error: $e");
    }
  }

  // Gọi API Login Phone của Backend
  Future<void> _callBackendPhoneLogin(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/login-firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int userId = data['userId'];
        widget.onVerifySuccess(userId);
      } else {
        _showError("Lỗi xác thực từ Server: ${response.body}");
      }
    } catch (e) {
      _showError("Không thể kết nối đến máy chủ");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AuthColors.gradientStart, AuthColors.gradientEnd]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text("Xác thực OTP",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                widget.isEmailMode
                    ? "Đã gửi mã đến ${widget.contactInfo}"
                    : "Đã gửi mã đến số điện thoại",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                            6,
                            (index) => SizedBox(
                                  width: 45,
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    onChanged: (val) =>
                                        _onOtpChanged(val, index),
                                    decoration: InputDecoration(
                                        counterText: "",
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                  ),
                                )),
                      ),
                      const SizedBox(height: 30),
                      Text("Gửi lại sau ${_resendTimer}s",
                          style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text("Xác nhận"),
                        ),
                      ),
                      TextButton(
                          onPressed: widget.onBack,
                          child: const Text("Quay lại")),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}