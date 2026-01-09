import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/trip_controller.dart';

class TripleTapWrapper extends StatefulWidget {
  final Widget child;
  final int? userId;

  const TripleTapWrapper({super.key, required this.child, this.userId});

  @override
  State<TripleTapWrapper> createState() => _TripleTapWrapperState();
}

class _TripleTapWrapperState extends State<TripleTapWrapper> {
  int _tapCount = 0;
  Timer? _timer;

  void _handleTap() {
    // Nếu chưa có userId (chưa đăng nhập) thì không làm gì cả
    if (widget.userId == null) return;

    setState(() {
      _tapCount++;
    });

    // Reset bộ đếm nếu sau 600ms không gõ thêm
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () {
      setState(() {
        _tapCount = 0;
      });
    });

    // Khi gõ đủ 3 lần
    if (_tapCount == 3) {
      _timer?.cancel();
      _tapCount = 0;
      _triggerEmergency();
    }
  }

  void _triggerEmergency() async {
    final tripController = Provider.of<TripController>(context, listen: false);
    
    // Gọi hàm triggerPanic đã có sẵn trong hệ thống của bạn
    await tripController.triggerPanic(widget.userId!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🆘 Đã gửi tín hiệu khẩn cấp bằng Triple Tap!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Cho phép chạm xuyên qua các nút bên dưới
      onTap: _handleTap,
      child: widget.child,
    );
  }
}