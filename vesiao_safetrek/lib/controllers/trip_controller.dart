import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../common/constants.dart'; // Đảm bảo import đúng file chứa Constants

class TripController extends ChangeNotifier {
  // --- 1. TRẠNG THÁI UI & TIMER ---
  bool isMonitoring = false;
  int selectedMinutes = 15;
  int _remainingSeconds = 0;
  Timer? _timer;
  double progress = 1.0;
  String formattedTime = "15:00";
  
  // Lưu trữ ID chuyến đi và User ID hiện tại
  int? currentTripId; 
  
  // Lấy Base URL từ Constants (giống AuthController)
  final String baseUrl = Constants.baseUrl;

  void setDuration(int minutes) {
    if (!isMonitoring) {
      selectedMinutes = minutes;
      formattedTime = "$minutes:00";
      notifyListeners();
    }
  }

  // --- 2. CÁC HÀM GỌI API (SERVER) ---

  // [API] Bắt đầu chuyến đi
  Future<bool> startTrip({required int userId, String? destinationName}) async {
    // 1. Cập nhật UI trước để app phản hồi nhanh
    isMonitoring = true;
    _remainingSeconds = selectedMinutes * 60;
    progress = 1.0;
    notifyListeners();
    _startTimer();

    // 2. Gọi API
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
        currentTripId = data['tripId']; // Lưu ID chuyến đi để dùng cho Stop/Panic
        print("✅ Trip Started: ID $currentTripId");
        return true;
      } else {
        print("❌ Server Error (Start Trip): ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Connection Error (Start Trip): $e");
      return false;
    }
  }

  // [API] Kết thúc chuyến đi (An toàn hoặc Cưỡng ép)
  Future<void> stopTrip({required bool isSafe}) async {
    // 1. Dừng Timer UI
    isMonitoring = false;
    _timer?.cancel();
    notifyListeners();

    if (currentTripId == null) {
      print("⚠️ No Active Trip ID to stop.");
      return;
    }

    // 2. Gọi API
    try {
      final url = Uri.parse('$baseUrl/trips/$currentTripId/end');
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "status": isSafe ? "COMPLETED_SAFE" : "DURESS_ENDED"
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Trip Ended: ${isSafe ? 'Safe' : 'Duress'}");
      } else {
        print("❌ Server Error (Stop Trip): ${response.body}");
      }
    } catch (e) {
      print("❌ Connection Error (Stop Trip): $e");
    }
  }

  // [API] Kích hoạt Khẩn cấp (Panic)
  Future<void> triggerPanic(int userId) async {
    print("🚨 Triggering Panic...");
    
    // Tọa độ giả lập (Thực tế nên dùng Geolocator để lấy vị trí thật)
    double lat = 21.0285;
    double lng = 105.8542;

    try {
      final url = Uri.parse('$baseUrl/emergency/panic');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "lat": lat,
          "lng": lng,
          "tripId": currentTripId // Gửi kèm nếu đang trong chuyến đi
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Panic Sent Successfully: ${response.body}");
      } else {
        print("❌ Panic Failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Connection Error (Panic): $e");
    }
  }

  // [API] Xác thực mã PIN
  // Trả về String: "SAFE", "DURESS", hoặc "INVALID"/"ERROR"
  Future<String> verifyPin(int userId, String pin) async {
    try {
      final url = Uri.parse('$baseUrl/trips/verify-pin');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "pin": pin
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Server trả về: { "status": "SAFE" } hoặc { "status": "DURESS" }
        return data['status'] ?? "INVALID";
      } else {
        print("❌ Verify PIN Failed: ${response.body}");
        return "INVALID";
      }
    } catch (e) {
      print("❌ Connection Error (Verify PIN): $e");
      return "ERROR";
    }
  }

  // --- 3. LOGIC NỘI BỘ ---

  void _startTimer() {
    _timer?.cancel(); // Hủy timer cũ nếu có
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        
        // Tính toán progress bar
        double totalSeconds = selectedMinutes * 60.0;
        progress = _remainingSeconds / totalSeconds;

        // Format thời gian hiển thị (MM:SS)
        int min = _remainingSeconds ~/ 60;
        int sec = _remainingSeconds % 60;
        formattedTime = "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
        
        notifyListeners();
      } else {
        _timer?.cancel();
        // Hết giờ -> Logic tự động (ví dụ: Tự động gọi Panic)
        // triggerPanic(userId); // Cần userId để gọi cái này
        print("⚠️ Timer finished - Should trigger Auto Panic here");
      }
    });
  }
}