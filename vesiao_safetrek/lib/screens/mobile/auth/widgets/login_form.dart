import 'package:flutter/material.dart';
import '../../../../common/constants.dart'; // Import kPrimaryColor của dự án
import '../utils/auth_colors.dart';
import 'social_button.dart';

class LoginForm extends StatelessWidget {
  final bool isEmailMode;
  final TextEditingController phoneController;
  final TextEditingController emailController;
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
    required this.phoneError,
    required this.emailError,
    required this.isButtonActive,
    required this.onSubmit,
    required this.onSwitchMode,
  });

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
            isEmailMode
                ? "Nhập gmail để tiếp tục"
                : "Nhập số điện thoại để tiếp tục",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),

          // LABEL
          Text(
            isEmailMode ? "Gmail" : "Số điện thoại",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // INPUT FIELD
          TextField(
            controller: isEmailMode ? emailController : phoneController,
            keyboardType:
                isEmailMode ? TextInputType.emailAddress : TextInputType.phone,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: isEmailMode ? "VD: xxxxx@gmail.com" : "VD: 0912345678",
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: isEmailMode ? emailError : phoneError,
              prefixIcon: Icon(
                isEmailMode ? Icons.email_outlined : Icons.phone_outlined,
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // INFO BOX
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuthColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: kPrimaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmailMode
                            ? "Tại sao dùng gmail"
                            : "Tại sao dùng số điện thoại",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AuthColors.infoTextBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEmailMode
                            ? "Chúng tôi dùng gmail để gửi mã xác thực và khôi phục tài khoản"
                            : "Người thân dễ nhận biết khi nhận cảnh báo \"SĐT 09xx đang gặp nguy hiểm\"",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: kPrimaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CONTINUE BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onSubmit,
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
                "Tiếp tục",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // DIVIDER
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

          // SOCIAL BUTTONS
          SocialButton(
            text: "Đăng nhập bằng Gmail",
            icon: Icons.g_mobiledata_rounded,
            onPressed: () => onSwitchMode(true),
          ),
          const SizedBox(height: 12),
          SocialButton(
            text: "Đăng nhập bằng SĐT",
            icon: Icons.phone_in_talk_outlined,
            onPressed: () => onSwitchMode(false),
          ),

          const SizedBox(height: 30),

          // TERMS
          Center(
            child: Text.rich(
              TextSpan(
                text: "Bằng việc đăng nhập, bạn đồng ý với ",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                children: [
                  TextSpan(
                    text: "Điều khoản sử dụng",
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                  const TextSpan(text: " và "),
                  TextSpan(
                    text: "Chính sách\nbảo mật",
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}