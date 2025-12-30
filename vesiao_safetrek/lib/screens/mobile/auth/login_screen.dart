import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vesiao_safetrek/common/constants.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/utils/auth_colors.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/widgets/login_form.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/verify_pin_screen.dart'; // Màn xác thực PIN
import 'package:vesiao_safetrek/screens/mobile/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isEmailMode = false;

  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _identityError;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _identityController.addListener(_checkButtonActive);
    _passwordController.addListener(_checkButtonActive);
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkButtonActive() {
    setState(() {
      bool isIdentityValid = _isEmailMode 
        ? _identityController.text.contains('@') 
        : _identityController.text.length >= 9;
      _isButtonActive = isIdentityValid && _passwordController.text.length >= 6;
    });
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _identityError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': _identityController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // ĐĂNG NHẬP THÀNH CÔNG -> CHUYỂN QUA NHẬP PIN
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyPinScreen(
              userId: data['user']['userId'],
              userName: data['user']['fullName'] ?? "User",
            ),
          ),
        );
      } else {
        _showError(jsonDecode(response.body)['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AuthColors.gradientStart, AuthColors.gradientEnd],
                begin: Alignment.topLeft, end: Alignment.bottomRight
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
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LoginForm(
                          isEmailMode: _isEmailMode,
                          identityController: _identityController,
                          passwordController: _passwordController,
                          identityError: _identityError,
                          isButtonActive: _isButtonActive,
                          onSubmit: _handleLogin,
                          onRegisterTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                          onSwitchMode: (val) => setState(() {
                            _isEmailMode = val;
                            _identityController.clear();
                            _checkButtonActive();
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
