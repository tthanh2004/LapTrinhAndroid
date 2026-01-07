import 'package:flutter/material.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/utils/auth_colors.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/widgets/login_form.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/register_screen.dart';

// [MỚI] Import Service và Màn hình chính
import '../../../../services/auth_service.dart';
import '../mobile_screen.dart'; 

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

  // [MỚI] Khởi tạo AuthService
  final AuthService _authService = AuthService();

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

  // [ĐÃ SỬA] Sử dụng AuthService để đăng nhập và lưu Token
  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _identityError = null;
    });

    // Gọi AuthService (đã bao gồm gọi API + Lưu Token vào máy)
    final result = await _authService.login(
      _identityController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result['success']) {
      final userId = result['data']['user']['userId'];
      
      // Đăng nhập thành công -> Vào thẳng màn hình chính (MobileScreen)
      // Thay vì vào VerifyPinScreen (thường chỉ dùng khi mở lại app đã đăng nhập)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MobileScreen(userId: userId),
        ),
        (route) => false, // Xóa hết lịch sử quay lại màn Login
      );
    } else {
      // Đăng nhập thất bại
      setState(() => _isLoading = false);
      _showError(result['message'] ?? "Đăng nhập thất bại");
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