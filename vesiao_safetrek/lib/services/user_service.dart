import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class UserService {
  // Lấy thông tin user
  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/auth/profile/$userId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy profile: $e");
    }
    return null;
  }

  // Cập nhật FCM Token
  Future<void> updateFcmToken(int userId, String token) async {
    try {
      await http.patch(
        Uri.parse('${Constants.baseUrl}/auth/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'token': token}),
      );
      print("✅ Đã cập nhật FCM Token lên server");
    } catch (e) {
      print("❌ Lỗi update token: $e");
    }
  }
}