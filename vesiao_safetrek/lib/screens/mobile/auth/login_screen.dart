import 'package:flutter/material.dart';
import '../mobile_screen.dart'; // Import màn hình chính của bạn
import 'utils/auth_colors.dart';
import 'widgets/login_form.dart';
import 'widgets/otp_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- QUẢN LÝ TRẠNG THÁI ---
  bool _showOTP = false;
  bool _isEmailMode = false; // false = SĐT, true = Gmail

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Biến lưu thông báo lỗi (Validation)
  String? _phoneError;
  String? _emailError;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkButtonActive);
    _emailController.addListener(_checkButtonActive);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Check sơ bộ để đổi màu nút
  void _checkButtonActive() {
    setState(() {
      if (_isEmailMode && _emailError != null) _emailError = null;
      if (!_isEmailMode && _phoneError != null) _phoneError = null;

      if (_isEmailMode) {
        _isButtonActive = _emailController.text.isNotEmpty;
      } else {
        _isButtonActive = _phoneController.text.length >= 9;
      }
    });
  }

  // VALIDATE INPUT
  bool _validateInputs() {
    if (_isEmailMode) {
      final email = _emailController.text.trim();
      final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
      
      if (email.isEmpty) {
        setState(() => _emailError = "Vui lòng nhập Gmail");
        return false;
      } else if (!gmailRegex.hasMatch(email)) {
        setState(() => _emailError = "Gmail không hợp lệ (VD: abc@gmail.com)");
        return false;
      }
      return true;
    } else {
      final phone = _phoneController.text.trim();
      final phoneRegex = RegExp(r'^(0)(3|5|7|8|9)([0-9]{8})$');

      if (phone.isEmpty) {
        setState(() => _phoneError = "Vui lòng nhập số điện thoại");
        return false;
      } else if (!phoneRegex.hasMatch(phone)) {
        setState(() => _phoneError = "SĐT không hợp lệ (VD: 0912345678)");
        return false;
      }
      return true;
    }
  }

  void _handleSubmit() {
    if (_validateInputs()) {
      setState(() => _showOTP = true);
    }
  }

  void _switchToMode(bool isEmail) {
    if (_isEmailMode != isEmail) {
      setState(() {
        _isEmailMode = isEmail;
        _isButtonActive = false;
        _phoneError = null;
        _emailError = null;
        _checkButtonActive();
      });
    }
  }

  void _onLoginSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MobileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nếu showOTP = true thì hiện màn hình OTP
    if (_showOTP) {
      return OtpForm(
        contactInfo: _isEmailMode ? _emailController.text : _phoneController.text,
        isEmailMode: _isEmailMode,
        onVerifySuccess: _onLoginSuccess,
        onBack: () => setState(() => _showOTP = false),
      );
    }

    // Nếu không thì hiện màn hình Login
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
                colors: [AuthColors.gradientStart, AuthColors.gradientEnd],
              ),
            ),
          ),

          // Content
          Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: AuthColors.gradientEnd, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "SafeTrek",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Vệ Sĩ Ảo của bạn",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),

              // Form Sheet chứa LoginForm
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  // Gọi Widget Login Form đã tách
                  child: LoginForm(
                    isEmailMode: _isEmailMode,
                    phoneController: _phoneController,
                    emailController: _emailController,
                    phoneError: _phoneError,
                    emailError: _emailError,
                    isButtonActive: _isButtonActive,
                    onSubmit: _handleSubmit,
                    onSwitchMode: _switchToMode,
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