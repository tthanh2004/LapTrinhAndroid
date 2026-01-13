class Guardian {
  final int id; // ID của quan hệ bảo vệ (guardianId)
  final int userId; // ID của người dùng (nếu có)
  final String name;
  final String phone;
  final String status; // ACCEPTED, PENDING, REJECTED

  Guardian({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.status,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'] ?? json['guardianId'] ?? 0,
      userId: json['userId'] ?? 0,
      name: json['name'] ?? 'Không tên',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'PENDING',
    );
  }

  // Getter helper để kiểm tra trạng thái nhanh
  bool get isAccepted => status == 'ACCEPTED';
  bool get isPending => status == 'PENDING';
}