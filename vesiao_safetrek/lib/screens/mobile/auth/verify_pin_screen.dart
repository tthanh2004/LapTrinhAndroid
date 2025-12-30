import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vesiao_safetrek/common/constants.dart';
import 'package:vesiao_safetrek/screens/mobile/mobile_screen.dart';

class VerifyPinScreen extends StatefulWidget {
  final int userId;
  final String userName;
  const VerifyPinScreen({super.key, required this.userId, required this.userName});
  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) _focusNodes[index + 1].requestFocus();
      else { _focusNodes[index].unfocus(); _handleVerify(); }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handleVerify() async {
    String pin = _controllers.map((e) => e.text).join();
    if (pin.length < 4) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/verify-safe-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId, 'pin': pin}),
      );

      if (response.statusCode == 200) {
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MobileScreen(userId: widget.userId)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mã PIN không đúng"), backgroundColor: Colors.red));
        for(var c in _controllers) c.clear(); _focusNodes[0].requestFocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.blue)),
            const SizedBox(height: 20),
            const Text("Xác thực tài khoản", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Xin chào, ${widget.userName}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const Spacer(flex: 1),
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text("Nhập mã PIN an toàn để tiếp tục", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) => SizedBox(width: 60, height: 60, child: TextField(
                        controller: _controllers[i], focusNode: _focusNodes[i], obscureText: true, textAlign: TextAlign.center,
                        keyboardType: TextInputType.number, maxLength: 1, onChanged: (v) => _onPinChanged(v, i),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ))),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF9C4), foregroundColor: Colors.black87),
                      child: _isLoading ? const CircularProgressIndicator() : const Text("Nhập mã để tiếp tục"),
                    )),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Đổi tài khoản"))),
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