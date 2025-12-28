import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase
import 'package:http/http.dart' as http;
import '../common/constants.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = Constants.baseUrl;

  String? _verificationId; // Lưu ID phiên giao dịch OTP

  // 1. GỬI YÊU CẦU OTP (FIREBASE)
  Future<void> sendOtpFirebase(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    // Định dạng lại sđt: 09xx -> +849xx (Bắt buộc với Firebase)
    String formattedPhone = phoneNumber;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,

      // Tự động xác thực (Chỉ Android làm được khi tin nhắn tới)
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential);
      },

      // Lỗi (Sai SHA-1, hết hạn mức...)
      verificationFailed: (FirebaseAuthException e) {
        print("Lỗi Firebase: ${e.message}");
        onError(e.message ?? "Lỗi xác thực");
      },

      // Đã gửi mã thành công -> Chuyển sang màn nhập mã
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        print("Đã gửi mã tới $formattedPhone");
        onCodeSent(verificationId);
      },

      // Hết thời gian chờ
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // 2. XÁC NHẬN MÃ OTP & LOGIN BACKEND
  Future<bool> verifyOtpFirebase(String smsCode) async {
    try {
      // Tạo credential từ mã người dùng nhập
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      return await _signInWithCredential(credential);
    } catch (e) {
      print("Sai mã OTP: $e");
      return false;
    }
  }

  // Hàm phụ: Lấy Token gửi lên Backend
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      // 1. Đăng nhập vào Firebase trước
      UserCredential userCred = await _auth.signInWithCredential(credential);
      User? firebaseUser = userCred.user;

      if (firebaseUser != null) {
        // 2. Lấy ID Token (Chuỗi xác thực dài ngoằng)
        String? token = await firebaseUser.getIdToken();
        print("Firebase Token: $token");

        // 3. Gửi Token này lên Backend NestJS để lưu vào DB chính
        return await _loginBackend(token!);
      }
      return false;
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return false;
    }
  }

  // GỌI API LOGIN CỦA SERVER MÌNH
  Future<bool> _loginBackend(String firebaseToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login-firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': firebaseToken}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Backend Login Success: UserID ${data['userId']}");
        return true;
      } else {
        print("Backend Refused: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Backend Error: $e");
      return false;
    }
  }
}
