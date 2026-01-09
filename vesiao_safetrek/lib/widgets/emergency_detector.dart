import 'package:flutter/material.dart';

class EmergencyDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEmergencyTriggered;

  const EmergencyDetector({
    super.key,
    required this.child,
    required this.onEmergencyTriggered,
  });

  @override
  State<EmergencyDetector> createState() => _EmergencyDetectorState();
}

class _EmergencyDetectorState extends State<EmergencyDetector> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  
  // Thời gian tối đa giữa các lần chạm (ví dụ: 500ms). 
  // Nếu chạm quá chậm sẽ reset lại bộ đếm.
  static const int _maxGapBetweenTaps = 500; 

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null) {
      final difference = now.difference(_lastTapTime!).inMilliseconds;
      
      if (difference > _maxGapBetweenTaps) {
        // Nếu khoảng cách giữa 2 lần chạm quá lâu, reset về 1
        _tapCount = 1;
      } else {
        _tapCount++;
      }
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    if (_tapCount == 5) {
      // Đã chạm đủ 5 lần liên tiếp
      _tapCount = 0; // Reset bộ đếm
      _lastTapTime = null;
      print("Đã phát hiện 5 lần chạm: KÍCH HOẠT KHẨN CẤP!");
      widget.onEmergencyTriggered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // HitTestBehavior.translucent giúp bắt sự kiện chạm ngay cả khi 
      // chạm vào khoảng trống hoặc các widget con.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleTap(),
      child: widget.child,
    );
  }
}