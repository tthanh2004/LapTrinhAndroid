import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vesiao_safetrek/screens/mobile/mobile_screen.dart';
import 'utils/auth_colors.dart';
import 'widgets/login_form.dart';
import 'widgets/otp_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showOTP = false;
  bool _isEmailMode = false;
  bool _isLoading = false; // Thêm trạng thái loading

  // Biến lưu ID xác thực cho SĐT
  String? _verificationId;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _phoneError;
  String? _emailError;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkButtonActive);
    _emailController.addListener(_checkButtonActive);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _checkButtonActive() {
    setState(() {
      if (_isEmailMode) {
        _isButtonActive = _emailController.text.isNotEmpty;
      } else {
        _isButtonActive = _phoneController.text.length >= 9;
      }
    });
  }

  bool _validateInputs() {
    // Reset lỗi
    setState(() {
      _phoneError = null;
      _emailError = null;
    });

    if (_isEmailMode) {
      final email = _emailController.text.trim();
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
        setState(() => _emailError = "Vui lòng nhập đúng định dạng Gmail");
        return false;
      }
      return true;
    } else {
      final phone = _phoneController.text.trim();
      if (!RegExp(r'^(0?)(3|5|7|8|9)([0-9]{8})$').hasMatch(phone)) {
        setState(() => _phoneError = "SĐT không hợp lệ");
        return false;
      }
      return true;
    }
  }

  // --- LOGIC XỬ LÝ NÚT TIẾP TỤC ---
  void _handleSubmit() async {
    if (!_validateInputs()) return;

    if (_isEmailMode) {
      // Nếu là Email: Chuyển sang màn OTP ngay (Màn OTP sẽ tự gọi API gửi mail)
      setState(() => _showOTP = true);
    } else {
      // Nếu là SĐT: Phải gửi SMS trước
      await _handlePhoneLogin();
    }
  }

  // --- LOGIC GỬI SMS (FIREBASE) ---
  Future<void> _handlePhoneLogin() async {
    setState(() => _isLoading = true);
    
    String phone = _phoneController.text.trim();
    // Chuyển 09xx -> +849xx
    String formattedPhone = phone.startsWith("0") 
        ? "+84${phone.substring(1)}" 
        : "+84$phone";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Tự động xác thực (ít xảy ra, nhưng nếu có thì login luôn)
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi gửi SMS: ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
          _verificationId = verificationId; // Lưu ID để dùng ở bước nhập OTP
          _showOTP = true; // Chuyển màn hình
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _onLoginSuccess(int userId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MobileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // HIỂN THỊ MÀN HÌNH OTP
    if (_showOTP) {
      return OtpForm(
        contactInfo: _isEmailMode ? _emailController.text : _phoneController.text,
        isEmailMode: _isEmailMode,
        verificationId: _verificationId, // Truyền ID xác thực sang OTP Form
        onVerifySuccess: (id) => _onLoginSuccess(id),
        onBack: () => setState(() => _showOTP = false),
      );
    }

    // HIỂN THỊ MÀN HÌNH LOGIN
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AuthColors.gradientStart, AuthColors.gradientEnd],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.shield, color: Colors.white, size: 80),
                const Text("SafeTrek",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30))),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : LoginForm(
                          isEmailMode: _isEmailMode,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          phoneError: _phoneError,
                          emailError: _emailError,
                          isButtonActive: _isButtonActive,
                          onSubmit: _handleSubmit,
                          onSwitchMode: (val) => setState(() {
                            _isEmailMode = val;
                            _checkButtonActive();
                            _phoneError = null;
                            _emailError = null;
                          }),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}