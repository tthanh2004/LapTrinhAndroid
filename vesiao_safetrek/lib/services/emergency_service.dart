import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../common/constants.dart';

class EmergencyService {
  // Hàm lấy vị trí và gửi SOS
  Future<void> sendEmergencyAlert(int userId, {int? tripId, int? batteryLevel}) async {
    try {
      // 1. Lấy vị trí (Logic xin quyền nên để ở UI hoặc Controller, ở đây chỉ gọi hàm)
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2. Gọi API
      final url = Uri.parse('${Constants.baseUrl}/emergency/panic');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "lat": position.latitude,
          "lng": position.longitude,
          "tripId": tripId,
          "batteryLevel": batteryLevel ?? 0, 
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Gửi SOS thành công: ${position.latitude}, ${position.longitude}");
      } else {
        print("❌ Lỗi Server SOS: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi ngoại lệ SOS: $e");
    }
  }
}