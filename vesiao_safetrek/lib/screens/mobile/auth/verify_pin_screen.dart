import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import các thành phần cần thiết
import '../../../../common/constants.dart';
import '../../../../services/auth_service.dart'; // [QUAN TRỌNG] Để lưu đăng nhập
import '../mobile_screen.dart'; // Màn hình chính

class VerifyPinScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const VerifyPinScreen({
    super.key, 
    required this.userId, 
    required this.userName
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  // Quản lý 4 ô nhập số
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  bool _isLoading = false;
  final AuthService _authService = AuthService(); // Service xử lý lưu token

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  // Tự động chuyển ô khi nhập số
  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handleVerify(); // Nhập đủ 4 số tự động verify
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // Xử lý logic Verify
  void _handleVerify() async {
    String pin = _controllers.map((e) => e.text).join();
    if (pin.length < 4) return;
    
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/verify-safe-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId, 
          'pin': pin
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // --- PIN ĐÚNG ---
        
        // 1. Lưu trạng thái đăng nhập vào máy
        // (Trong thực tế, API verify nên trả về token, ở đây ta lưu userId để đánh dấu đã login)
        await _authService.saveLoginInfo(widget.userId, "verified_token_placeholder");

        if (mounted) {
           // 2. Chuyển vào màn hình chính
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (context) => MobileScreen(userId: widget.userId)),
             (route) => false, // Xóa hết màn hình Login/Verify khỏi stack
           );
        }
      } else {
        // --- PIN SAI ---
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? "Mã PIN không chính xác");
        _clearPin();
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
      _clearPin();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red)
      );
    }
  }

  void _clearPin() {
    for(var c in _controllers) c.clear(); 
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600], // Màu nền chủ đạo
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Avatar & Welcome Text
            const CircleAvatar(
              radius: 40, 
              backgroundColor: Colors.white, 
              child: Icon(Icons.lock_person, size: 40, color: Colors.blue)
            ),
            const SizedBox(height: 20),
            const Text(
              "Xác thực bảo mật", 
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              "Xin chào, ${widget.userName}", 
              style: const TextStyle(color: Colors.white70, fontSize: 16)
            ),
            const Spacer(flex: 1),
            
            // Khung nhập liệu màu trắng bo tròn
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30))
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Nhập mã PIN an toàn (4 số)", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)
                    ),
                    const SizedBox(height: 30),
                    
                    // 4 ô nhập PIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) => SizedBox(
                        width: 60, height: 60,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          obscureText: true, // Ẩn số thành dấu chấm
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          onChanged: (v) => _onPinChanged(v, i),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: "",
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2)
                            )
                          ),
                        ),
                      )),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Nút xác nhận
                    SizedBox(
                      width: double.infinity, 
                      height: 50, 
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700], // Màu nút đậm hơn
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("Xác nhận", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Nút đổi tài khoản
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text("Đăng nhập bằng tài khoản khác", style: TextStyle(color: Colors.grey))
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}