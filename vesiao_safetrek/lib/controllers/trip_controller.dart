import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class TripController extends ChangeNotifier {
  // --- STATE ---
  bool isMonitoring = false;
  int selectedMinutes = 15;
  String formattedTime = "00:00";
  Timer? _timer;
  int _remainingSeconds = 0;

  int? currentTripId; 
  final int currentUserId = 1; 
  // LƯU Ý: Giữ nguyên IP mà bạn đang chạy được (Ví dụ IP dây cáp USB)
  final String baseUrl = Constants.baseUrl; 

  void setDuration(int minutes) {
    selectedMinutes = minutes;
    notifyListeners();
  }

  // 1. START TRIP
  Future<void> startTrip(String? destination) async {
    try {
      final url = Uri.parse('$baseUrl/trips/start');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': currentUserId,
          'durationMinutes': selectedMinutes,
          'destinationName': destination,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        currentTripId = data['tripId'];
        isMonitoring = true;
        _startTimer();
        notifyListeners();
      } else {
        print("Lỗi Server: ${response.body}");
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
    }
  }

  // 2. STOP TRIP
  Future<void> stopTrip({bool isSafe = true}) async {
    if (currentTripId == null) return;
    try {
      final url = Uri.parse('$baseUrl/trips/$currentTripId/end');
      await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': isSafe ? 'COMPLETED_SAFE' : 'DURESS_ENDED'
        }),
      );
      _timer?.cancel();
      isMonitoring = false;
      currentTripId = null;
      notifyListeners();
    } catch (e) {
      print("Lỗi stop: $e");
    }
  }

  // 3. PANIC
  Future<void> sendPanicAlert() async {
    try {
      final url = Uri.parse('$baseUrl/trips/panic');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': currentUserId, 'tripId': currentTripId}),
      );
    } catch (e) {
      print("Lỗi panic: $e");
    }
  }

  // 4. CHECK PIN (MỚI)
  // Trả về: 'SAFE', 'DURESS', 'INVALID' hoặc 'ERROR'
  Future<String> verifyPin(String pin) async {
    try {
      final url = Uri.parse('$baseUrl/trips/verify-pin');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': currentUserId, 'pin': pin}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status']; 
      }
    } catch (e) {
      print("Lỗi check PIN: $e");
    }
    return "ERROR";
  }

  void _startTimer() {
    _remainingSeconds = selectedMinutes * 60;
    _updateFormattedTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _updateFormattedTime();
        notifyListeners();
      } else {
        sendPanicAlert(); 
        timer.cancel();
      }
    });
  }

  void _updateFormattedTime() {
    int min = _remainingSeconds ~/ 60;
    int sec = _remainingSeconds % 60;
    formattedTime = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }
}