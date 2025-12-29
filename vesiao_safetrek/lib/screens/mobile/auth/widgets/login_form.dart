import 'package:flutter/material.dart';
import '../../../../common/constants.dart'; // Import màu kPrimaryColor
import '../utils/auth_colors.dart';
import 'social_button.dart';

class LoginForm extends StatefulWidget {
  final bool isEmailMode;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController; // [MỚI] Controller cho pass
  final String? phoneError;
  final String? emailError;
  final bool isButtonActive;
  final VoidCallback onSubmit;
  final Function(bool) onSwitchMode;

  const LoginForm({
    super.key,
    required this.isEmailMode,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.phoneError,
    required this.emailError,
    required this.isButtonActive,
    required this.onSubmit,
    required this.onSwitchMode,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true; // Trạng thái ẩn hiện mật khẩu

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Đăng nhập",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isEmailMode
                ? "Nhập gmail và mật khẩu để tiếp tục"
                : "Nhập số điện thoại và mật khẩu để tiếp tục",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),

          // --- 1. EMAIL / SĐT ---
          Text(
            widget.isEmailMode ? "Gmail" : "Số điện thoại",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.isEmailMode
                ? widget.emailController
                : widget.phoneController,
            keyboardType: widget.isEmailMode
                ? TextInputType.emailAddress
                : TextInputType.phone,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText:
                  widget.isEmailMode ? "VD: xxxxx@gmail.com" : "VD: 0912345678",
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText:
                  widget.isEmailMode ? widget.emailError : widget.phoneError,
              prefixIcon: Icon(
                widget.isEmailMode
                    ? Icons.email_outlined
                    : Icons.phone_outlined,
                color: Colors.grey[500],
              ),
              filled: true,
              fillColor: AuthColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. MẬT KHẨU [MỚI] ---
          const Text(
            "Mật khẩu",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.passwordController,
            obscureText: _obscurePassword, // Ẩn mật khẩu
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: "Nhập mật khẩu",
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[500],
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: AuthColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryColor),
              ),
            ),
          ),

          // Nút Quên mật khẩu
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text("Quên mật khẩu?",
                  style: TextStyle(color: kPrimaryColor)),
            ),
          ),

          const SizedBox(height: 10),

          // NÚT ĐĂNG NHẬP
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.isButtonActive ? widget.onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                disabledBackgroundColor: AuthColors.buttonDisabled,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // CÁC PHẦN DƯỚI GIỮ NGUYÊN
          Row(
            children: const [
              Expanded(child: Divider(color: AuthColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("hoặc", style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: AuthColors.border)),
            ],
          ),
          const SizedBox(height: 24),
          SocialButton(
            text: widget.isEmailMode
                ? "Đăng nhập bằng SĐT"
                : "Đăng nhập bằng Gmail",
            icon: widget.isEmailMode
                ? Icons.phone_in_talk_outlined
                : Icons.g_mobiledata_rounded,
            onPressed: () => widget.onSwitchMode(!widget.isEmailMode),
          ),
          const SizedBox(height: 30),
          // ... (Phần Terms giữ nguyên)
        ],
      ),
    );
  }
}