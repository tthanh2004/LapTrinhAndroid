import 'package:flutter/material.dart';
import '../../../../services/guardian_service.dart';

class ProtectedListScreen extends StatefulWidget {
  final int userId;
  const ProtectedListScreen({super.key, required this.userId});

  @override
  State<ProtectedListScreen> createState() => _ProtectedListScreenState();
}

class _ProtectedListScreenState extends State<ProtectedListScreen> {
  final GuardianService _guardianService = GuardianService();
  List<dynamic> _protectedPeople = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load từ API thật
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _guardianService.fetchPeopleIProtect(widget.userId);
    if (mounted) {
      setState(() {
        _protectedPeople = data;
        _isLoading = false;
      });
    }
  }

  // Xử lý Chấp nhận/Từ chối
  Future<void> _handleResponse(int guardianId, bool accept) async {
    bool success = await _guardianService.respondToRequest(guardianId, accept);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? "Đã chấp nhận" : "Đã từ chối"), backgroundColor: accept ? Colors.green : Colors.grey),
      );
      _loadData(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Có lỗi xảy ra, vui lòng thử lại"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB), // Xanh Royal Blue
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0, // Giảm khoảng cách để icon gần nút back hơn
        title: Row(
          children: [
            const Icon(Icons.people_alt_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Danh sách người đang bảo vệ",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${_protectedPeople.length} người đang bảo vệ",
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      children: [
                        // Hộp thông tin (Giống ảnh)
                        _buildInfoBox(),
                        const SizedBox(height: 20),

                        if (_protectedPeople.isEmpty)
                          _buildEmptyState()
                        else
                          ..._protectedPeople.map((person) => _buildPersonCard(person)),
                        
                        // Không có nút "Thêm" ở đây vì đây là danh sách thụ động
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Blue 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Danh sách này là gì?",
            style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            "Đây là những người đã thêm bạn làm người bảo vệ. Bạn sẽ nhận được thông báo SOS khi họ gặp nguy hiểm.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Chưa có ai thêm bạn làm người bảo vệ", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(dynamic item) {
    final user = item['protectedUser'];
    final status = item['status'];
    final guardianId = item['guardianId'];
    
    bool isAccepted = status == 'ACCEPTED';
    String fullName = user['fullName'] ?? "Không tên";
    String phone = user['phoneNumber'] ?? "";
    String firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar màu xanh dương nhạt giống ảnh
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFDBEAFE), // Blue 100
                  child: Text(
                    firstLetter, 
                    style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                ),
                const SizedBox(width: 16),
                
                // Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Trạng thái
                      if (isAccepted)
                        Row(
                          children: const [
                            Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF22C55E)), // Green
                            SizedBox(width: 4),
                            Text(
                              "Đã chấp nhận",
                              style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: const [
                            Icon(Icons.access_time, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              "Đang chờ xác nhận",
                              style: TextStyle(color: Colors.orange, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Xóa icon thùng rác (để giống ảnh)
              ],
            ),
            
            // Nếu chưa chấp nhận (PENDING) -> Hiển thị nút bấm
            if (!isAccepted) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleResponse(guardianId, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Từ chối"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleResponse(guardianId, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Chấp nhận"),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}