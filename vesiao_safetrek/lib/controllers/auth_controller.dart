import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class AuthService {
  final String baseUrl = Constants.baseUrl;

  // Gọi API login backend
  Future<Map<String, dynamic>> loginBackend(String firebaseToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login-firebase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': firebaseToken}),
    );
    // Trả về dữ liệu thô hoặc ném lỗi, không xử lý logic ở đây
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }
}