import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/trip_service.dart';
import '../services/emergency_service.dart';

class TripController extends ChangeNotifier {
  final TripService _tripService = TripService();
  final EmergencyService _emergencyService = EmergencyService();

  bool isMonitoring = false;
  int selectedMinutes = 15;
  int _remainingSeconds = 0;
  Timer? _timer;
  double progress = 1.0;
  String formattedTime = "15:00";
  int? currentTripId;
  int _pinErrorCount = 0;
  String? currentDestination;

  void setDuration(int minutes) {
    if (!isMonitoring) {
      selectedMinutes = minutes;
      formattedTime = "$minutes:00";
      notifyListeners();
    }
  }

  // [MỚI] Hàm gia hạn thời gian
  void extendTrip(int minutes) {
    if (!isMonitoring) return;
    _remainingSeconds += (minutes * 60);
    
    // Cập nhật hiển thị ngay lập tức
    int min = _remainingSeconds ~/ 60;
    int sec = _remainingSeconds % 60;
    formattedTime = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
    
    notifyListeners();
  }

  Future<bool> startTrip({required int userId, String? destinationName}) async {
    isMonitoring = true;
    _pinErrorCount = 0;
    _remainingSeconds = selectedMinutes * 60;
    progress = 1.0;
    currentDestination = destinationName;
    notifyListeners();
    _startTimer(userId);

    try {
      final data = await _tripService.startTripApi(userId, selectedMinutes, destinationName);
      currentTripId = data['tripId'];
      return true;
    } catch (e) {
      print("Lỗi Start Trip: $e");
      return false;
    }
  }

  Future<void> stopTrip({required bool isSafe}) async {
    isMonitoring = false;
    currentDestination = null;
    _timer?.cancel();
    notifyListeners();

    if (currentTripId != null) {
      // API: PATCH /trips/:id/end
      await _tripService.endTripApi(currentTripId!, isSafe ? "COMPLETED_SAFE" : "DURESS_ENDED");
    }
  }

  Future<void> triggerPanic(int userId) async {
    int battery = await Battery().batteryLevel;
    // API: POST /emergency/panic
    await _emergencyService.sendEmergencyAlert(
      userId, 
      tripId: currentTripId,
      batteryLevel: battery
    );
  }

  Future<String> verifyPin(int userId, String pin) async {
    // API: POST /trips/verify-pin
    return await _tripService.verifyPinApi(userId, pin);
  }

  int incrementPinError() {
    _pinErrorCount++;
    return _pinErrorCount;
  }

  void _startTimer(int userId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        
        // Tính toán lại progress tương đối
        int totalOriginalSeconds = selectedMinutes * 60;
        if (totalOriginalSeconds == 0) totalOriginalSeconds = 1; // Tránh chia cho 0
        progress = (_remainingSeconds / totalOriginalSeconds).clamp(0.0, 1.0);

        int min = _remainingSeconds ~/ 60;
        int sec = _remainingSeconds % 60;
        formattedTime = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
        notifyListeners();
      } else {
        _timer?.cancel();
        triggerPanic(userId);
      }
    });
  }
}