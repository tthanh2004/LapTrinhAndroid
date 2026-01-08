import 'package:flutter/material.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/utils/auth_colors.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/widgets/login_form.dart';
import 'package:vesiao_safetrek/screens/mobile/auth/register_screen.dart';

// [MỚI] Import Service và màn hình xác thực PIN
import '../../../../services/auth_service.dart';
import 'verify_pin_screen.dart'; // <--- Thêm import này

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Trạng thái UI
  bool _isLoading = false;
  bool _isEmailMode = false;
  bool _isButtonActive = false;
  String? _identityError;

  // Controllers
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Khởi tạo AuthService
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

  // --- LOGIC ĐĂNG NHẬP (ĐÃ SỬA: Chuyển sang VerifyPinScreen) ---
  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _identityError = null;
    });

    // 1. Gọi API đăng nhập
    final result = await _authService.login(
      _identityController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    // 2. Xử lý kết quả
    if (result['success']) {
      final userId = result['data']['user']['userId'];
      final userName = result['data']['user']['fullName']; // Lấy tên để hiển thị chào mừng
      
      // [THAY ĐỔI TẠI ĐÂY] 
      // Đăng nhập thành công -> Chuyển sang màn hình nhập PIN
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VerifyPinScreen(
            userId: userId,
            userName: userName ?? "Người dùng",
          ),
        ),
      );
    } else {
      // Thất bại -> Hiện lỗi
      setState(() => _isLoading = false);
      _showError(result['message'] ?? "Đăng nhập thất bại");
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
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AuthColors.gradientStart, AuthColors.gradientEnd],
                begin: Alignment.topLeft, end: Alignment.bottomRight
              ),
            ),
          ),
          
          // Nội dung chính
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.shield, color: Colors.white, size: 80),
                const Text(
                  "SafeTrek", 
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 30),
                
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30))
                    ),
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LoginForm(
                          isEmailMode: _isEmailMode,
                          identityController: _identityController,
                          passwordController: _passwordController,
                          identityError: _identityError,
                          isButtonActive: _isButtonActive,
                          onSubmit: _handleLogin, 
                          
                          onRegisterTap: () => Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const RegisterScreen())
                          ),
                          
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