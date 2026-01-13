import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/constants.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  final int userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  // Màu sắc theo thiết kế
  final Color _kDangerColor = const Color(0xFFDC2626);
  final Color _kDangerBg = const Color(0xFFFEF2F2);
  final Color _kPrimaryColor = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _markAllAsRead();
    await _fetchNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      await http.patch( // 1. Đổi sang PATCH
        Uri.parse('${Constants.baseUrl}/emergency/notifications/read-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.baseUrl}/emergency/notifications/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _notifications = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuardianResponse(int guardianId, bool isAccepted) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/emergency/guardians/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guardianId': guardianId,
          'status': isAccepted ? 'ACCEPTED' : 'REJECTED'
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isAccepted ? "Đã chấp nhận lời mời" : "Đã từ chối lời mời"),
            backgroundColor: isAccepted ? Colors.green : Colors.grey,
          ),
        );
        _fetchNotifications(); // Load lại danh sách để cập nhật trạng thái
      }
    } catch (e) {
      debugPrint("Lỗi kết nối: $e");
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri googleUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Không thể mở bản đồ")));
        }
      }
    } catch (e) {
      debugPrint("Lỗi mở map: $e");
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Màu nền xám nhạt
      appBar: AppBar(
        title: const Text("Thông báo",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Chưa có thông báo nào",
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isEmergency = notif['type'] == 'EMERGENCY';

                    // Parse Data JSON
                    Map<String, dynamic>? dataObj;
                    if (notif['data'] != null) {
                      try {
                        dataObj = jsonDecode(notif['data']);
                      } catch (_) {}
                    }

                    if (isEmergency) {
                      return _buildEmergencyCard(notif, dataObj);
                    } else {
                      return _buildStandardCard(notif, dataObj);
                    }
                  },
                ),
    );
  }

  // --- 1. CARD CẢNH BÁO SOS (Giao diện giống ảnh upload) ---
  Widget _buildEmergencyCard(dynamic notif, Map<String, dynamic>? dataObj) {
    // Lấy thông tin từ dataObj (Backend cần gửi các trường này)
    final double? lat = double.tryParse(dataObj?['lat']?.toString() ?? '');
    final double? lng = double.tryParse(dataObj?['lng']?.toString() ?? '');
    final String batteryLevel = dataObj?['batteryLevel']?.toString() ?? 'Unknown'; 
    // Lưu ý: Backend cần gửi key 'batteryLevel' trong body JSON

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDangerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: _kDangerColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header Đỏ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kDangerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.warning_amber_rounded,
                      color: _kDangerColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notif['title'] ?? "CẢNH BÁO SOS!",
                    style: TextStyle(
                        color: _kDangerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Text(
                  _formatDate(notif['createdAt']).split(' - ')[0], // Chỉ lấy giờ
                  style: TextStyle(color: _kDangerColor.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          
          // Nội dung chi tiết (Bullet points)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.my_location, "Vị trí GPS",
                    (lat != null && lng != null) ? "$lat, $lng" : "Không xác định"),
                const SizedBox(height: 12),
                
                // [MỚI] Hiển thị Mức Pin
                _buildInfoRow(Icons.battery_alert, "Mức pin điện thoại", 
                    batteryLevel != 'Unknown' ? "$batteryLevel%" : "-- %"),
                
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, "Thời gian cảnh báo", 
                    _formatDate(notif['createdAt'])),

                const SizedBox(height: 16),
                
                // Nút xem bản đồ
                if (lat != null && lng != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(lat, lng),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text("Xem vị trí trên bản đồ"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDangerColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con hiển thị dòng thông tin (Icon + Label + Value)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. CARD THÔNG BÁO THƯỜNG (Lời mời kết bạn) ---
  Widget _buildStandardCard(dynamic notif, Map<String, dynamic>? dataObj) {
    final bool isRequest = notif['type'] == 'GUARDIAN_REQUEST';
    final String? currentStatus = notif['currentGuardianStatus'];
    int? guardianId = dataObj?['guardianId'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue[50], shape: BoxShape.circle),
                child:
                    Icon(Icons.person_add, color: _kPrimaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif['title'] ?? "Thông báo",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'] ?? "",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Nút bấm Chấp nhận/Từ chối
          if (isRequest && guardianId != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            currentStatus == 'PENDING'
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _handleGuardianResponse(guardianId, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Chấp nhận"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _handleGuardianResponse(guardianId, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Từ chối"),
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: currentStatus == 'ACCEPTED'
                          ? Colors.green[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentStatus == 'ACCEPTED'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 18,
                          color: currentStatus == 'ACCEPTED'
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentStatus == 'ACCEPTED'
                              ? "Đã chấp nhận kết nối"
                              : "Đã từ chối kết nối",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentStatus == 'ACCEPTED'
                                ? Colors.green[800]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}