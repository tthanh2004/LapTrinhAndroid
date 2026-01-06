import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // [QUAN TRỌNG] Nhớ import cái này
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
      await http.post(
        Uri.parse('${Constants.baseUrl}/emergency/notifications/read-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/emergency/notifications/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
            content: Text(isAccepted ? "Đã chấp nhận lời mời" : "Đã từ chối lời mời"),
            backgroundColor: isAccepted ? Colors.green : Colors.grey,
          ),
        );
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint("Lỗi kết nối: $e");
    }
  }

  // [MỚI] Hàm mở Google Maps
  Future<void> _openMap(double lat, double lng) async {
    // Tạo link Google Maps với tọa độ chính xác
    final Uri googleUrl = Uri.parse('http://maps.google.com/maps?q=$lat,$lng');
    
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể mở bản đồ")));
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
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                      Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Chưa có thông báo nào", style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isEmergency = notif['type'] == 'EMERGENCY';
                    final isRequest = notif['type'] == 'GUARDIAN_REQUEST';
                    
                    final String? currentStatus = notif['currentGuardianStatus'];

                    int? guardianId;
                    if (isRequest && notif['data'] != null) {
                      try {
                        final dataObj = jsonDecode(notif['data']);
                        guardianId = dataObj['guardianId'];
                      } catch (_) {}
                    }

                    // Bọc Container trong GestureDetector để bắt sự kiện click
                    return GestureDetector(
                      onTap: () {
                        // [MỚI] Xử lý khi bấm vào thông báo KHẨN CẤP
                        if (isEmergency && notif['data'] != null) {
                          try {
                            final dataObj = jsonDecode(notif['data']);
                            final lat = double.parse(dataObj['lat'].toString());
                            final lng = double.parse(dataObj['lng'].toString());
                            _openMap(lat, lng);
                          } catch (e) {
                            debugPrint("Lỗi parse tọa độ: $e");
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: Border.all(
                            color: isEmergency ? Colors.red.withOpacity(0.2) : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isEmergency ? Colors.red[50] : Colors.blue[50],
                                child: Icon(
                                  isEmergency ? Icons.warning_amber_rounded : Icons.person_add_alt_1,
                                  color: isEmergency ? Colors.red : Colors.blue,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                notif['title'] ?? "Thông báo",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isEmergency ? Colors.red[700] : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    notif['body'] ?? "",
                                    style: const TextStyle(color: Colors.black54, height: 1.3),
                                  ),
                                  // Hiển thị thêm dòng hướng dẫn nếu là tin khẩn cấp
                                  if (isEmergency)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Nhấn để xem vị trí",
                                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(notif['createdAt']),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Phần nút bấm cho Guardian Request (Giữ nguyên)
                            if (isRequest && guardianId != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                child: currentStatus == 'PENDING'
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _handleGuardianResponse(guardianId!, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text("Chấp nhận"),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _handleGuardianResponse(guardianId!, false),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.grey[700],
                                                side: BorderSide(color: Colors.grey[300]!),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text("Từ chối"),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: currentStatus == 'ACCEPTED' ? Colors.green[50] : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: currentStatus == 'ACCEPTED' ? Colors.green[200]! : Colors.grey[300]!
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              currentStatus == 'ACCEPTED' ? Icons.check_circle : Icons.cancel,
                                              size: 18,
                                              color: currentStatus == 'ACCEPTED' ? Colors.green : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              currentStatus == 'ACCEPTED' ? "Bạn đã chấp nhận" : "Bạn đã từ chối",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: currentStatus == 'ACCEPTED' ? Colors.green[800] : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}