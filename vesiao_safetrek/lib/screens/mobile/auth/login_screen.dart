import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vesiao_safetrek/screens/mobile/auth/utils/auth_colors.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/widgets/login_form.dart';
import 'package:vesiao_safetrek/screens/mobile/mobile_screen.dart';
import 'package:vesiao_safetrek/common/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // [SỬA Ở ĐÂY] Đổi thành true để mặc định là Email
  bool _isEmailMode = true; 
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _phoneError;
  String? _emailError;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkButtonActive);
    _emailController.addListener(_checkButtonActive);
    _passwordController.addListener(_checkButtonActive);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkButtonActive() {
    setState(() {
      bool isIdentityValid = _isEmailMode
          ? _emailController.text.isNotEmpty
          : _phoneController.text.length >= 9;
      
      bool isPasswordValid = _passwordController.text.length >= 6;
      
      _isButtonActive = isIdentityValid && isPasswordValid;
    });
  }

  bool _validateInputs() {
    setState(() {
      _phoneError = null;
      _emailError = null;
    });

    if (_isEmailMode) {
      final email = _emailController.text.trim();
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
        setState(() => _emailError = "Vui lòng nhập đúng định dạng Gmail");
        return false;
      }
    } else {
      final phone = _phoneController.text.trim();
      if (!RegExp(r'^(0?)(3|5|7|8|9)([0-9]{8})$').hasMatch(phone)) {
        setState(() => _phoneError = "SĐT không hợp lệ");
        return false;
      }
    }
    return true;
  }

  void _handleLogin() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    String identity = _isEmailMode 
        ? _emailController.text.trim() 
        : _phoneController.text.trim();
    
    if (!_isEmailMode && identity.startsWith("0")) {
       identity = "+84${identity.substring(1)}";
    }

    final String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/login-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': identity,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        int userId = data['user']['userId'];
        _onLoginSuccess(userId);
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      _showError("Lỗi kết nối máy chủ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _onLoginSuccess(int userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MobileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const Text("SafeTrek",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30))),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : LoginForm(
                            isEmailMode: _isEmailMode,
                            phoneController: _phoneController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            phoneError: _phoneError,
                            emailError: _emailError,
                            isButtonActive: _isButtonActive,
                            onSubmit: _handleLogin,
                            onSwitchMode: (val) => setState(() {
                              _isEmailMode = val;
                              _checkButtonActive();
                              _phoneError = null;
                              _emailError = null;
                            }),
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