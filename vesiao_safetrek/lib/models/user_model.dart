class User {
  final int userId;
  final String? phoneNumber;
  final String? fullName;
  final String? email;
  final String? fcmToken;

  User({
    required this.userId,
    this.phoneNumber,
    this.fullName,
    this.email,
    this.fcmToken,
  });

  // Factory để chuyển từ JSON (Server) -> Object (Dart)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? 0, // Giá trị mặc định nếu null
      phoneNumber: json['phoneNumber'] ?? json['identity'], // Backend có thể trả về identity hoặc phoneNumber
      fullName: json['fullName'] ?? json['name'],
      email: json['email'],
      fcmToken: json['fcmToken'],
    );
  }

  // Chuyển từ Object -> JSON (để gửi lên Server)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'email': email,
      'fcmToken': fcmToken,
    };
  }
}