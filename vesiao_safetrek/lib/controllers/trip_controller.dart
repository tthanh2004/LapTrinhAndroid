import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // [MỚI] Thêm thư viện GPS
import '../common/constants.dart';

class TripController extends ChangeNotifier {
  // --- STATE ---
  bool isMonitoring = false;
  int selectedMinutes = 15;
  String formattedTime = "00:00";
  Timer? _timer;
  int _remainingSeconds = 0;

  int? currentTripId;
  // Mặc định là 0, sẽ được setUserId cập nhật từ UI
  int currentUserId = 0; 
  final String baseUrl = Constants.baseUrl;

  // Hàm để UI cập nhật ID người dùng hiện tại vào Controller
  void setUserId(int id) {
    currentUserId = id;
  }

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

      if (response.statusCode == 201 || response.statusCode == 200) {
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

  // 3. [NÂNG CẤP] GỬI PANIC (KÈM VỊ TRÍ GPS)
  // Hàm này giờ đây tự lo mọi thứ: Lấy GPS -> Gửi API -> Trả về kết quả
  Future<bool> sendPanicAlert() async {
    try {
      // A. Lấy vị trí GPS hiện tại
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      // Lấy vị trí chính xác cao
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // B. Gọi API Panic
      final url = Uri.parse('$baseUrl/emergency/panic');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': currentUserId,
          'lat': position.latitude,
          'lng': position.longitude,
          'tripId': currentTripId // Có thể null nếu bấm ở Home (không trong chuyến đi)
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Đã gửi SOS thành công tại: ${position.latitude}, ${position.longitude}");
        return true;
      } else {
        print("❌ Lỗi Server Panic: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi Panic Exception: $e");
      return false;
    }
  }

  // 4. [NÂNG CẤP] CHECK PIN & TỰ ĐỘNG PANIC
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
        String status = data['status'];

        // [QUAN TRỌNG] Nếu là mã DURESS (Khẩn cấp) -> Tự động kích hoạt Panic ngầm
        if (status == 'DURESS') {
          print("⚠️ Phát hiện mã PIN khẩn cấp! Đang gửi tọa độ...");
          sendPanicAlert(); // Gọi hàm ở trên, không cần await để UI phản hồi ngay
        }

        return status; 
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
        // Hết giờ -> Tự động Panic
        print("⏳ Hết giờ! Tự động gửi SOS...");
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