// lib/screens/mobile/auth/security/verify_pin_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../common/constants.dart';
import 'create_new_pin_screen.dart'; // Import màn hình tạo PIN mới

class VerifyPinScreen extends StatefulWidget {
  // [MỚI] Thêm userId để biết đang đổi PIN cho ai
  final int userId; 
  const VerifyPinScreen({super.key, required this.userId, required userName});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final _pinController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isObscure = true;
  bool _isLoading = false;

  // Hàm kiểm tra PIN cũ trước khi cho đổi
  void _checkOldPin() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/verify-safe-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'pin': _pinController.text
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        // PIN cũ đúng -> Chuyển sang màn hình tạo PIN mới
        // [QUAN TRỌNG] Truyền userId sang
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => CreateNewPinScreen(userId: widget.userId)
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mã PIN hiện tại không đúng"), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            color: kPrimaryColor,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context), 
                  child: Row(children: const [Icon(Icons.arrow_back, color: Colors.white), SizedBox(width: 8), Text("Quay lại", style: TextStyle(color: Colors.white, fontSize: 16))])
                ),
                const SizedBox(height: 20),
                const Text("Xác thực PIN cũ", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16), 
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), 
                  child: Row(children: const [Icon(Icons.lock, color: kPrimaryColor), SizedBox(width: 10), Expanded(child: Text("Nhập mã PIN an toàn hiện tại để tiếp tục", style: TextStyle(color: kPrimaryColor)))])
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _pinController, 
                  obscureText: _isObscure, 
                  keyboardType: TextInputType.number, 
                  maxLength: 4,
                  onChanged: (val) => setState(() => _isButtonEnabled = val.length == 4),
                  style: const TextStyle(fontSize: 18, letterSpacing: 5),
                  decoration: InputDecoration(
                    hintText: "****", 
                    counterText: "", 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _isObscure = !_isObscure)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: (_isButtonEnabled && !_isLoading) ? _checkOldPin : null,
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Tiếp tục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}