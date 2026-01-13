import 'package:flutter/material.dart';
import '../../../../common/constants.dart'; // Import constant màu sắc
import '../../../../services/auth_service.dart'; // [QUAN TRỌNG] Import Service

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  
  // Khởi tạo Service
  final AuthService _authService = AuthService();

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _safePinController = TextEditingController();
  final _duressPinController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _safePinController.dispose();
    _duressPinController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    // Validate cơ bản
    if (_fullNameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Vui lòng điền đầy đủ thông tin");
      return;
    }
    if (_safePinController.text.length != 4 || _duressPinController.text.length != 4) {
      _showError("Mã PIN phải có 4 số");
      return;
    }
    if (_safePinController.text == _duressPinController.text) {
      _showError("Hai mã PIN không được trùng nhau");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // [SỬA 2] Gọi qua Service (Chuẩn MVC) thay vì http.post trực tiếp
      final result = await _authService.register({
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        // Lưu ý: Key gửi lên phải khớp với Backend quy định (passwordHash hay password)
        'passwordHash': _passwordController.text, 
        'safePinHash': _safePinController.text,
        'duressPinHash': _duressPinController.text,
      });

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Quay về màn hình Login
      } else {
        _showError(result['message'] ?? "Lỗi đăng ký");
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDangerColor),
      );
    }
  }

  Widget _buildInput(TextEditingController ctrl, String label, {bool isPass = false, TextInputType? type, int? len}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: type,
      maxLength: len,
      decoration: InputDecoration(
        labelText: label,
        counterText: "", // Ẩn bộ đếm ký tự
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký tài khoản", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thông tin cá nhân", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _buildInput(_fullNameController, "Họ và tên"),
              const SizedBox(height: 16),
              _buildInput(_phoneController, "Số điện thoại", type: TextInputType.phone),
              const SizedBox(height: 16),
              _buildInput(_emailController, "Email (Tùy chọn)", type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildInput(_passwordController, "Mật khẩu", isPass: true),
              
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              
              const Text("Thiết lập bảo mật (Bắt buộc)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor)),
              const SizedBox(height: 10),
              _buildInput(_safePinController, "Safe PIN (4 số)", type: TextInputType.number, len: 4),
              const SizedBox(height: 16),
              _buildInput(_duressPinController, "Duress PIN (4 số - Khẩn cấp)", type: TextInputType.number, len: 4),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Đăng ký ngay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}