import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../common/constants.dart';
import '../../../../../services/user_service.dart'; // Import service để lấy/lưu data

class PersonalInfoScreen extends StatefulWidget {
  final int userId; // [MỚI] Cần nhận userId
  const PersonalInfoScreen({super.key, required this.userId});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Không hardcode nữa
  
  bool _isButtonEnabled = false;
  bool _isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _nameController.addListener(_validate);
    _emailController.addListener(_validate);
  }

  // 1. Load dữ liệu từ Server
  Future<void> _loadUserData() async {
    final profile = await _userService.getUserProfile(widget.userId);
    if (mounted && profile != null) {
      setState(() {
        _nameController.text = profile['fullName'] ?? "";
        _emailController.text = profile['email'] ?? "";
        _phoneController.text = profile['phoneNumber'] ?? "";
        _isLoading = false;
      });
    }
  }

  // 2. Hàm gọi API cập nhật thông tin
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.patch(
        Uri.parse('${Constants.baseUrl}/auth/profile/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _nameController.text,
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true); // Trả về true để màn hình trước reload lại
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
        );
      } else {
        throw Exception("Lỗi server");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Có lỗi xảy ra, vui lòng thử lại"), backgroundColor: Colors.red),
      );
    }
  }

  void _validate() {
    setState(() {
      _isButtonEnabled = _nameController.text.isNotEmpty && 
                         _emailController.text.isNotEmpty;
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
                  child: Row(children: const [
                    Icon(Icons.arrow_back, color: Colors.white), 
                    SizedBox(width: 8), 
                    Text("Quay lại", style: TextStyle(color: Colors.white, fontSize: 16))
                  ]),
                ),
                const SizedBox(height: 20),
                const Text("Thông tin cá nhân", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildAvatar(),
                        const SizedBox(height: 30),
                        _buildTextField("Họ và tên", _nameController, Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildTextField("Email", _emailController, Icons.email_outlined),
                        const SizedBox(height: 20),
                        // Số điện thoại thường không cho sửa (readOnly = true)
                        _buildTextField("Số điện thoại", _phoneController, Icons.phone_outlined, isReadOnly: true),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity, 
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isButtonEnabled ? _updateProfile : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor, 
                              foregroundColor: Colors.white, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
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
        Container(
          width: 100, height: 100, 
          decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimaryColor, border: Border.all(color: Colors.white, width: 4)), 
          child: const Icon(Icons.person, size: 60, color: Colors.white)
        ),
        Positioned(
          bottom: 0, right: 0, 
          child: Container(
            padding: const EdgeInsets.all(6), 
            decoration: BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), 
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)
          )
        ),
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
            prefixIcon: Icon(icon, color: Colors.grey), 
            filled: true, 
            fillColor: isReadOnly ? Colors.grey[200] : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}