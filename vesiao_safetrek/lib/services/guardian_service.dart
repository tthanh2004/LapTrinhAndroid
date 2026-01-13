import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/constants.dart';
import '../models/guardian_model.dart';

class GuardianService {
  // Lấy danh sách người bảo vệ
  Future<List<Guardian>> fetchGuardians(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/emergency/guardians/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Map từ JSON sang List<Guardian>
        return data.map((json) => Guardian.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching guardians: $e");
      return [];
    }
  }

  // Thêm người bảo vệ
  Future<bool> addGuardian(int userId, String name, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/emergency/guardians'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'name': name,
          'phone': phone,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Xóa người bảo vệ
  Future<bool> deleteGuardian(int guardianId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/emergency/guardians/$guardianId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> fetchPeopleIProtect(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/emergency/protecting/$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching protecting list: $e");
      return [];
    }
  }

  // [MỚI] Phản hồi lời mời (Chấp nhận/Từ chối) - Dùng lại API đã làm ở phần Thông báo
  Future<bool> respondToRequest(int guardianId, bool accept) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/emergency/guardians/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guardianId': guardianId,
          'status': accept ? 'ACCEPTED' : 'REJECTED'
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}