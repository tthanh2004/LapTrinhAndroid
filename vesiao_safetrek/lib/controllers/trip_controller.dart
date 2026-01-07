import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // [QUAN TRỌNG] Thêm import này
import '../common/constants.dart';

class TripController extends ChangeNotifier {
  // --- 1. STATE UI ---
  bool isMonitoring = false;
  int selectedMinutes = 15;
  int _remainingSeconds = 0;
  Timer? _timer;
  double progress = 1.0;
  String formattedTime = "15:00";
  int? currentTripId; 
  
  // URL API
  final String baseUrl = Constants.baseUrl;

  // Cập nhật thời gian chọn
  void setDuration(int minutes) {
    if (!isMonitoring) {
      selectedMinutes = minutes;
      formattedTime = "$minutes:00";
      notifyListeners();
    }
  }

  // --- 2. CÁC HÀM API ---

  // [API] Bắt đầu chuyến đi
  Future<bool> startTrip({required int userId, String? destinationName}) async {
    // Cập nhật UI ngay lập tức
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
        print("✅ Trip started: ID $currentTripId");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error starting trip: $e");
      return false;
    }
  }

  // [API] Kết thúc chuyến đi
  Future<void> stopTrip({required bool isSafe}) async {
    isMonitoring = false;
    _timer?.cancel();
    notifyListeners();

    if (currentTripId == null) return;

    try {
      await http.patch(
        Uri.parse('$baseUrl/trips/$currentTripId/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "status": isSafe ? "COMPLETED_SAFE" : "DURESS_ENDED"
        }),
      );
    } catch (e) {
      print("Error stop trip: $e");
    }
  }

  // [API] Trigger Panic (Đã cập nhật lấy GPS thật)
  Future<void> triggerPanic(int userId) async {
    print("🚨 Triggering Panic...");
    
    double lat = 0.0;
    double lng = 0.0;

    // 1. Lấy vị trí thực tế
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Lấy tọa độ hiện tại (High accuracy)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      lat = position.latitude;
      lng = position.longitude;
      print("📍 Current Location: $lat, $lng");

    } catch (e) {
      print("⚠️ Không lấy được GPS: $e");
      // Fallback: Nếu không lấy được GPS, gửi 0.0 hoặc xử lý tùy ý
    }

    // 2. Gọi API gửi tọa độ thật
    try {
      final url = Uri.parse('$baseUrl/emergency/panic');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "lat": lat, 
          "lng": lng, 
          "tripId": currentTripId // Gửi kèm TripID để server biết user đang đi
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Panic Sent Successfully");
      } else {
        print("❌ Panic Failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Connection Error (Panic): $e");
    }
  }

  // [API] Verify PIN
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
    } catch (e) {
      return "ERROR";
    }
  }

  // --- 3. LOGIC TIMER ---
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        double totalSeconds = selectedMinutes * 60.0;
        progress = _remainingSeconds / totalSeconds;
        int min = _remainingSeconds ~/ 60;
        int sec = _remainingSeconds % 60;
        formattedTime = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
        notifyListeners();
      } else {
        _timer?.cancel();
        // Hết giờ -> Logic tự động Panic nếu cần
        // if (currentTripId != null) triggerPanic(userId); 
      }
    });
  }
}