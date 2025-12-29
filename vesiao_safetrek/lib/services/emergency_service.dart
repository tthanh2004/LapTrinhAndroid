import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class EmergencyService {
  final String baseUrl = Constants.baseUrl;

  Future<void> sendEmergencyAlert(int userId) async {
    try {
      // 1. Kiểm tra quyền và lấy vị trí
      Position position = await _determinePosition();

      // 2. Gọi API gửi tín hiệu khẩn cấp
      final response = await http.post(
        Uri.parse('$baseUrl/emergency/panic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Đã gửi tín hiệu cứu hộ kèm vị trí: ${position.latitude}, ${position.longitude}");
      } else {
        print("❌ Lỗi Server: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi khẩn cấp: $e");
    }
  }

  // Hàm xử lý xin quyền và lấy tọa độ GPS
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Dịch vụ định vị bị tắt.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Quyền định vị bị từ chối.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // Độ chính xác cao nhất cho khẩn cấp
    );
  }
}