import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../common/constants.dart';

class AuthService {
  final String baseUrl = Constants.baseUrl;

  // --- 1. LOCAL STORAGE (Lưu/Lấy/Xóa Token) ---

  // Lưu token và userId
  Future<void> saveLoginInfo(int userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('authToken', token);
  }

  // Lấy thông tin (Tự động đăng nhập)
  Future<Map<String, dynamic>?> getLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final token = prefs.getString('authToken');
    if (userId != null && token != null) {
      return {'userId': userId, 'token': token};
    }
    return null;
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- 2. API CALLS (Gọi Server) ---

  // Hàm Đăng nhập
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': phone, 'password': password}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Tự động lưu token khi đăng nhập thành công
        await saveLoginInfo(data['user']['userId'], "dummy_token_if_jwt_implemented"); 
        // Lưu ý: Nếu backend trả về JWT token thật thì thay chuỗi dummy kia bằng data['accessToken']
        
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Hàm Đăng ký
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}