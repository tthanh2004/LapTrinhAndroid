import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../utils/auth_colors.dart';

class OtpForm extends StatefulWidget {
  final String contactInfo;
  final bool isEmailMode;
  final Function(int) onVerifySuccess; // Đã đổi thành truyền int (userId)
  final VoidCallback onBack;

  const OtpForm({
    super.key,
    required this.contactInfo,
    required this.isEmailMode,
    required this.onVerifySuccess,
    required this.onBack,
  });

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
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
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyOtp() {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6) {
      // Giả lập ID người dùng trả về từ API sau khi khớp OTP
      int userIdFromApi = 1; 
      widget.onVerifySuccess(userIdFromApi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AuthColors.gradientStart, AuthColors.gradientEnd]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text("Xác thực OTP", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(widget.contactInfo, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) => SizedBox(
                          width: 45,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            onChanged: (val) => _onOtpChanged(val, index),
                            decoration: InputDecoration(counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        )),
                      ),
                      const SizedBox(height: 30),
                      Text("Gửi lại sau ${_resendTimer}s", style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _verifyOtp,
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                          child: const Text("Xác nhận"),
                        ),
                      ),
                      TextButton(onPressed: widget.onBack, child: const Text("Quay lại")),
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