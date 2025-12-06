import 'package:flutter/material.dart';
import '../common/constants.dart';

class PinPad extends StatefulWidget {
  final Function(String) onPinSubmit;
  const PinPad({super.key, required this.onPinSubmit});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String pin = "";

  void _input(String num) {
    if (pin.length < 4) setState(() => pin += num);
    if (pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onPinSubmit(pin);
      });
    }
  }

  void _delete() {
    if (pin.isNotEmpty) setState(() => pin = pin.substring(0, pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, 
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // --- HEADER PIN PAD ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(height: 15),
                const Text("Xác nhận an toàn", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Nhập mã PIN của bạn", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          // --- BODY PIN PAD ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  
                  // Hiển thị chấm tròn PIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 50, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: index < pin.length ? kPrimaryColor : Colors.grey.shade300, 
                          width: 2
                        ),
                      ),
                      child: index < pin.length ? const Center(child: Text("•", style: TextStyle(fontSize: 30))) : null,
                    )),
                  ),

                  const SizedBox(height: 20),
                  
                  // Info Box xanh nhạt
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
                    child: Row(
                      children: const [
                        Icon(Icons.lock_outline, size: 18, color: kPrimaryColor),
                        SizedBox(width: 10),
                        Expanded(child: Text("Nhập mã PIN an toàn để xác nhận. Nếu bị ép buộc, hãy nhập mã PIN khẩn cấp.", style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // Bàn phím số
                  Wrap(
                    spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
                    children: [
                      ...['1','2','3','4','5','6','7','8','9'].map((n) => _buildBtn(n)),
                      _buildTextBtn("Xóa", onTap: _delete),
                      _buildBtn('0'),
                      _buildTextBtn("←", onTap: _delete),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(String val) => InkWell(
    onTap: () => _input(val),
    child: Container(
      width: 80, height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
    ),
  );

  Widget _buildTextBtn(String text, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Container(
      width: 80, height: 80,
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 16, color: kTextColor)),
    ),
  );
}