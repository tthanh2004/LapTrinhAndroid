import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class TripService {
  Future<Map<String, dynamic>> startTripApi(int userId, int duration, String? dest) async {
    final url = Uri.parse('${Constants.baseUrl}/trips/start');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": userId,
        "durationMinutes": duration,
        "destinationName": dest ?? "Unknown"
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body); // Trả về { tripId: 123, ... }
    } else {
      throw Exception("Lỗi khởi tạo chuyến đi: ${response.body}");
    }
  }

  Future<void> endTripApi(int tripId, String status) async {
    final url = Uri.parse('${Constants.baseUrl}/trips/$tripId/end');
    await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": status}), // "COMPLETED_SAFE" hoặc "DURESS_ENDED"
    );
  }

  Future<String> verifyPinApi(int userId, String pin) async {
    final url = Uri.parse('${Constants.baseUrl}/trips/verify-pin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"userId": userId, "pin": pin}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] ?? "INVALID";
    }
    return "ERROR";
  }
}