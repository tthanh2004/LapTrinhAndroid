import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class GuardianService {
  final String baseUrl = Constants.baseUrl;

  Future<List<dynamic>> fetchGuardians(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/emergency/guardians/$userId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) { print(e); }
    return [];
  }

  Future<bool> addGuardian(int userId, String name, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency/guardians'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'name': name, 'phone': phone}),
    );
    return response.statusCode == 201;
  }

  Future<bool> deleteGuardian(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/emergency/guardians/$id'));
    return response.statusCode == 200;
  }
}