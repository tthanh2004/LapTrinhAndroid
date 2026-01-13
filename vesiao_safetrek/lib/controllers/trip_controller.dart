import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/trip_service.dart';
import '../services/emergency_service.dart';

class TripController extends ChangeNotifier {
  // Services
  final TripService _tripService = TripService();
  final EmergencyService _emergencyService = EmergencyService();

  // State
  bool isMonitoring = false;
  int selectedMinutes = 15;
  int _remainingSeconds = 0;
  Timer? _timer;
  double progress = 1.0;
  String formattedTime = "15:00";
  int? currentTripId;
  int _pinErrorCount = 0;
  
  // [MỚI] Lưu trữ điểm đến để hiển thị khi màn hình Rebuild
  String? currentDestination; 

  // Set thời gian trước khi đi
  void setDuration(int minutes) {
    if (!isMonitoring) {
      selectedMinutes = minutes;
      formattedTime = "$minutes:00";
      notifyListeners();
    }
  }

  // Bắt đầu chuyến đi
  Future<bool> startTrip({required int userId, String? destinationName}) async {
    // 1. Cập nhật UI ngay lập tức
    isMonitoring = true;
    _pinErrorCount = 0;
    _remainingSeconds = selectedMinutes * 60;
    progress = 1.0;
    currentDestination = destinationName; // [MỚI] Lưu lại điểm đến
    
    notifyListeners();
    _startTimer(userId); // Truyền userId vào để dùng khi hết giờ

    // 2. Gọi API ngầm
    try {
      final data = await _tripService.startTripApi(userId, selectedMinutes, destinationName);
      currentTripId = data['tripId'];
      print("Trip Started: ID $currentTripId");
      return true;
    } catch (e) {
      print("Lỗi Start Trip: $e");
      // Nếu lỗi mạng nghiêm trọng, có thể cân nhắc stopTrip() tại đây
      return false;
    }
  }

  // Kết thúc chuyến đi (An toàn hoặc Bị ép buộc)
  Future<void> stopTrip({required bool isSafe}) async {
    isMonitoring = false;
    currentDestination = null; // [MỚI] Reset điểm đến
    _timer?.cancel();
    notifyListeners();

    if (currentTripId != null) {
      await _tripService.endTripApi(currentTripId!, isSafe ? "COMPLETED_SAFE" : "DURESS_ENDED");
    }
  }

  // Gửi Báo động khẩn cấp
  Future<void> triggerPanic(int userId) async {
    int battery = await Battery().batteryLevel;
    // Gọi Service tái sử dụng
    await _emergencyService.sendEmergencyAlert(
      userId, 
      tripId: currentTripId,
      batteryLevel: battery
    );
  }

  // Kiểm tra mã PIN
  Future<String> verifyPin(int userId, String pin) async {
    return await _tripService.verifyPinApi(userId, pin);
  }

  // Tăng biến đếm sai PIN
  int incrementPinError() {
    _pinErrorCount++;
    return _pinErrorCount;
  }

  // Logic đếm ngược
  void _startTimer(int userId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        progress = _remainingSeconds / (selectedMinutes * 60.0);
        int min = _remainingSeconds ~/ 60;
        int sec = _remainingSeconds % 60;
        formattedTime = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
        notifyListeners();
      } else {
        // HẾT GIỜ -> TỰ ĐỘNG BÁO ĐỘNG
        _timer?.cancel();
        print("⏰ Hết giờ! Kích hoạt SOS tự động.");
        triggerPanic(userId);
      }
    });
  }
}