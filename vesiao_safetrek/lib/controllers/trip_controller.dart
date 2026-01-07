import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; 
import '../common/constants.dart';

class TripController extends ChangeNotifier {
  bool isMonitoring = false;
  int selectedMinutes = 15;
  String formattedTime = "00:00";
  Timer? _timer;
  int _remainingSeconds = 0;

  int? currentTripId;
  int currentUserId = 0; 
  
  final String baseUrl = Constants.baseUrl;

  void setUserId(int id) {
    currentUserId = id;
    notifyListeners();
  }

  void setDuration(int minutes) {
    selectedMinutes = minutes;
    notifyListeners();
  }

  Future<void> startTrip(String? destination) async {
    if (currentUserId <= 0) {
      print("❌ Lỗi: Chưa có thông tin UserID");
      return;
    }

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
        print("✅ Trip Started: ID $currentTripId");
      } else {
        print("❌ Lỗi Server Start: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối: $e");
    }
  }

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
      print("✅ Trip Ended: ${isSafe ? 'Safe' : 'Duress'}");
    } catch (e) {
      print("❌ Lỗi Stop Trip: $e");
    }
  }

  // [HÀM QUAN TRỌNG ĐÃ SỬA]
  Future<bool> sendPanicAlert() async {
    try {
      print("⚠️ Đang chuẩn bị gửi SOS...");

      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
           position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        }
      } catch (gpsError) {
        print("⚠️ GPS Error: $gpsError");
      }

      // [QUAN TRỌNG] Đã trỏ về Emergency Controller
      final url = Uri.parse('$baseUrl/emergency/panic');
      
      final bodyData = {
        'userId': currentUserId,
        'lat': position?.latitude ?? 0.0, // Backend yêu cầu 'lat'
        'lng': position?.longitude ?? 0.0, // Backend yêu cầu 'lng'
        'tripId': currentTripId, 
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ SOS SENT SUCCESSFULLY!");
        return true;
      } else {
        print("❌ Server Refused Panic: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Panic Exception: $e");
      return false;
    }
  }

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
        String status = data['status'] ?? 'INVALID';

        if (status == 'DURESS') {
          print("⚠️ DURESS PIN! Triggering Panic...");
          sendPanicAlert(); 
        }
        return status; 
      }
    } catch (e) {
      print("❌ Error Verify PIN: $e");
    }
    return "ERROR";
  }

  void _startTimer() {
    _remainingSeconds = selectedMinutes * 60;
    _updateFormattedTime();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _updateFormattedTime();
        notifyListeners();
      } else {
        print("⏳ Timeout! Triggering SOS...");
        sendPanicAlert(); 
        stopTrip(isSafe: false);
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