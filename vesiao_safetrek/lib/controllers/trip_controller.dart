import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; 
import '../common/constants.dart';

class TripController extends ChangeNotifier {
  bool isMonitoring = false;
  int selectedMinutes = 15;
  int _remainingSeconds = 0;
  Timer? _timer;
  double progress = 1.0;
  String formattedTime = "15:00";
  int? currentTripId; 
  
  // NƠI DUY NHẤT QUẢN LÝ BIẾN ĐẾM SAI PIN
  int _pinErrorCount = 0;

  final String baseUrl = Constants.baseUrl;

  void setDuration(int minutes) {
    if (!isMonitoring) {
      selectedMinutes = minutes;
      formattedTime = "$minutes:00";
      notifyListeners();
    }
  }

  // Hàm tăng số lần sai và trả về kết quả
  int incrementPinError() {
    _pinErrorCount++;
    return _pinErrorCount;
  }

  Future<bool> startTrip({required int userId, String? destinationName}) async {
    _pinErrorCount = 0; // Reset khi bắt đầu chuyến mới
    isMonitoring = true;
    _remainingSeconds = selectedMinutes * 60;
    progress = 1.0;
    notifyListeners();
    _startTimer();

    try {
      final url = Uri.parse('$baseUrl/trips/start');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "durationMinutes": selectedMinutes,
          "destinationName": destinationName ?? "Unknown Destination"
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentTripId = data['tripId']; 
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopTrip({required bool isSafe}) async {
    isMonitoring = false;
    _timer?.cancel();
    notifyListeners();

    if (currentTripId == null) return;

    try {
      await http.patch(
        Uri.parse('$baseUrl/trips/$currentTripId/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": isSafe ? "COMPLETED_SAFE" : "DURESS_ENDED"}),
      );
    } catch (_) {}
  }

  Future<void> triggerPanic(int userId) async {
    double lat = 0.0;
    double lng = 0.0;

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}

    try {
      await http.post(
        Uri.parse('$baseUrl/emergency/panic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "lat": lat, 
          "lng": lng, 
          "tripId": currentTripId 
        }),
      );
    } catch (_) {}
  }

  Future<String> verifyPin(int userId, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/verify-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"userId": userId, "pin": pin}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['status'] ?? "INVALID";
      }
      return "INVALID";
    } catch (_) {
      return "ERROR";
    }
  }

  void _startTimer() {
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
        _timer?.cancel();
      }
    });
  }
}