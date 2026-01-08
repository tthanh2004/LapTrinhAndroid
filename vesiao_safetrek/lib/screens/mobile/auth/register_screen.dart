import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vesiao_safetrek/common/constants.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _safePinController = TextEditingController();
  final _duressPinController = TextEditingController();

  void _handleRegister() async {
    if (_safePinController.text.length != 4 || _duressPinController.text.length != 4) {
       _showError("Mã PIN phải có 4 số"); return;
    }
    if (_safePinController.text == _duressPinController.text) {
       _showError("Hai mã PIN không được trùng nhau"); return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          
          // 👇 PHẢI SỬA KEY NÀY THÀNH 'passwordHash'
          'passwordHash': _passwordController.text, 
          
          // 👇 Key này giữ nguyên (đã đúng)
          'safePinHash': _safePinController.text,     
          'duressPinHash': _duressPinController.text, 
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập."), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        _showError(jsonDecode(response.body)['message'] ?? "Lỗi đăng ký");
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

  Widget _buildInput(TextEditingController ctrl, String label, {bool isPass = false, TextInputType? type, int? len}) {
    return TextField(
      controller: ctrl, obscureText: isPass, keyboardType: type, maxLength: len,
      decoration: InputDecoration(labelText: label, counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản"), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
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
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Đăng ký ngay"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}