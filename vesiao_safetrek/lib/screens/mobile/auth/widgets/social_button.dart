import 'package:flutter/material.dart';
import '../utils/auth_colors.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  
  // 👇 [SỬA DÒNG NÀY] Đổi MaterialColor? thành Color?
  final Color? iconColor; 

  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AuthColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.black87,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color chấp nhận cả MaterialColor (Colors.red) lẫn Color thường (kPrimaryColor)
            Icon(icon, color: iconColor ?? Colors.black54, size: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}