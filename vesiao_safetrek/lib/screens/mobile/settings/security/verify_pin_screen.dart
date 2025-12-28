import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import 'create_new_pin_screen.dart';

class VerifyPinScreen extends StatefulWidget {
  const VerifyPinScreen({super.key});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final _pinController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isObscure = true;

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
                GestureDetector(onTap: () => Navigator.pop(context), child: Row(children: const [Icon(Icons.arrow_back, color: Colors.white), SizedBox(width: 8), Text("Quay lại", style: TextStyle(color: Colors.white, fontSize: 16))])),
                const SizedBox(height: 20),
                const Text("Đổi mã PIN", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), child: Row(children: const [Icon(Icons.lock, color: kPrimaryColor), SizedBox(width: 10), Expanded(child: Text("Nhập mã PIN an toàn hiện tại để xác thực", style: TextStyle(color: kPrimaryColor)))])),
                const SizedBox(height: 30),
                TextField(
                  controller: _pinController, obscureText: _isObscure, keyboardType: TextInputType.number, maxLength: 4,
                  onChanged: (val) => setState(() => _isButtonEnabled = val.length == 4),
                  style: const TextStyle(fontSize: 18, letterSpacing: 5),
                  decoration: InputDecoration(
                    hintText: "Nhập 4 chữ số", counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _isObscure = !_isObscure)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _isButtonEnabled ? () {
                      // Logic: Chuyển sang màn tạo mã PIN mới (thay thế màn hình này)
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CreateNewPinScreen()));
                    } : null,
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Xác thực", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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