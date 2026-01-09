import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class NotificationService {
  // Hàm gửi thông báo từ App -> Server -> App khác
  Future<void> sendPushNotification({
    required int receiverId, 
    required String title, 
    required String body
  }) async {
    try {
      // Gọi API Backend (API này bạn đã viết ở bước trước: /notifications/send)
      // Lưu ý: Endpoint trong code backend của bạn đang là /emergency/notifications/send 
      // (vì nó nằm trong EmergencyController)
      // Hãy kiểm tra lại đúng đường dẫn. 
      // Nếu bạn để @Post('send') trong EmergencyController thì url là: .../emergency/send
      
      final url = Uri.parse('${Constants.baseUrl}/emergency/notifications/send'); // Check lại url backend

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': receiverId,
          'title': title,
          'body': body,
          'type': 'NORMAL_MESSAGE' 
        }),
      );
      print("✅ Đã gửi lệnh push lên server");
    } catch (e) {
      print("❌ Lỗi gửi push: $e");
    }
  }
}