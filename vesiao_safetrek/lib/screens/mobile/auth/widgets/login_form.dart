import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../utils/auth_colors.dart';
import 'social_button.dart';

class LoginForm extends StatefulWidget {
  final bool isEmailMode;
  final TextEditingController identityController;
  final TextEditingController passwordController;
  final String? identityError;
  final bool isButtonActive;
  final VoidCallback onSubmit;
  final VoidCallback onRegisterTap;
  final Function(bool) onSwitchMode;

  const LoginForm({
    super.key,
    required this.isEmailMode,
    required this.identityController,
    required this.passwordController,
    required this.identityError,
    required this.isButtonActive,
    required this.onSubmit,
    required this.onRegisterTap,
    required this.onSwitchMode,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Đăng nhập", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(widget.isEmailMode ? "Nhập Email và mật khẩu" : "Nhập số điện thoại và mật khẩu", style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 30),

          // Input Identity
          Text(widget.isEmailMode ? "Email" : "Số điện thoại", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.identityController,
            keyboardType: widget.isEmailMode ? TextInputType.emailAddress : TextInputType.phone,
            decoration: InputDecoration(
              hintText: widget.isEmailMode ? "VD: abc@gmail.com" : "VD: 0912345678",
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: widget.identityError,
              prefixIcon: Icon(widget.isEmailMode ? Icons.email_outlined : Icons.phone_outlined, color: Colors.grey[500]),
              filled: true,
              fillColor: AuthColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          // Input Password
          const Text("Mật khẩu", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: "Nhập mật khẩu",
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AuthColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),

          // Nút Đăng nhập
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.isButtonActive ? widget.onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                disabledBackgroundColor: AuthColors.buttonDisabled,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Đăng nhập", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 24),

          // Nút Đăng ký (Đã thêm)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: widget.onRegisterTap,
                child: const Text("Đăng ký ngay", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Row(children: const [
            Expanded(child: Divider(color: AuthColors.border)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("hoặc", style: TextStyle(color: Colors.grey, fontSize: 13))),
            Expanded(child: Divider(color: AuthColors.border)),
          ]),
          const SizedBox(height: 30),

          // Nút Social
          SocialButton(
            text: "Đăng nhập bằng Gmail",
            icon: Icons.g_mobiledata_rounded,
            iconColor: Colors.red,
            onPressed: () => widget.onSwitchMode(true),
          ),
          const SizedBox(height: 16),
          SocialButton(
            text: "Đăng nhập bằng SĐT",
            icon: Icons.phone_android_outlined,
            iconColor: kPrimaryColor,
            onPressed: () => widget.onSwitchMode(false),
          ),
        ],
      ),
    );
  }
}