import 'package:flutter/material.dart';
import '../mobile_screen.dart';
import 'utils/auth_colors.dart';
import 'widgets/login_form.dart';
import 'widgets/otp_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showOTP = false;
  bool _isEmailMode = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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

  void _checkButtonActive() {
    setState(() {
      if (_isEmailMode) {
        _isButtonActive = _emailController.text.isNotEmpty;
      } else {
        _isButtonActive = _phoneController.text.length >= 9;
      }
    });
  }

  bool _validateInputs() {
    if (_isEmailMode) {
      final email = _emailController.text.trim();
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
        setState(() => _emailError = "Gmail không hợp lệ");
        return false;
      }
      return true;
    } else {
      final phone = _phoneController.text.trim();
      if (!RegExp(r'^(0)(3|5|7|8|9)([0-9]{8})$').hasMatch(phone)) {
        setState(() => _phoneError = "SĐT không hợp lệ");
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

  void _onLoginSuccess(int userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MobileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showOTP) {
      return OtpForm(
        contactInfo: _isEmailMode ? _emailController.text : _phoneController.text,
        isEmailMode: _isEmailMode,
        onVerifySuccess: (id) => _onLoginSuccess(id), // Nhận ID từ OtpForm
        onBack: () => setState(() => _showOTP = false),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AuthColors.gradientStart, AuthColors.gradientEnd],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.shield, color: Colors.white, size: 80),
                const Text("SafeTrek", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                    child: LoginForm(
                      isEmailMode: _isEmailMode,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      phoneError: _phoneError,
                      emailError: _emailError,
                      isButtonActive: _isButtonActive,
                      onSubmit: _handleSubmit,
                      onSwitchMode: (val) => setState(() { _isEmailMode = val; _checkButtonActive(); }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}