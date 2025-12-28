import 'package:flutter/material.dart';
import '../../../../common/constants.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: "12213453312"); // Read-only
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validate);
    _emailController.addListener(_validate);
  }

  void _validate() {
    setState(() {
      _isButtonEnabled = _nameController.text.isNotEmpty && _emailController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            color: kPrimaryColor,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(children: const [Icon(Icons.arrow_back, color: Colors.white), SizedBox(width: 8), Text("Quay lại", style: TextStyle(color: Colors.white, fontSize: 16))]),
                ),
                const SizedBox(height: 20),
                const Text("Thông tin cá nhân", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 30),
                  _buildTextField("Họ và tên", _nameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildTextField("Email", _emailController, Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildTextField("Số điện thoại", _phoneController, Icons.phone_outlined, isReadOnly: true),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? () => Navigator.pop(context) : null,
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimaryColor, border: Border.all(color: Colors.white, width: 4)), child: const Icon(Icons.person, size: 60, color: Colors.white)),
        Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 16))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, readOnly: isReadOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey), filled: true, fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}