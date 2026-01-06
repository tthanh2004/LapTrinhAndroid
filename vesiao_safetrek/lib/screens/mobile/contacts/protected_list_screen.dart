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

  Future<void> _handleResponse(int guardianId, bool accept) async {
    bool success = await _guardianService.respondToRequest(guardianId, accept);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? "Đã chấp nhận bảo vệ" : "Đã từ chối"), backgroundColor: accept ? Colors.green : Colors.grey),
      );
      _loadData(); // Tải lại danh sách
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Có lỗi xảy ra"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Người được bảo vệ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildInfoBox(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _protectedPeople.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _protectedPeople.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildPersonCard(_protectedPeople[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Bạn chưa bảo vệ ai cả", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFEFF6FF), // Blue 50
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Danh sách này là gì?", style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Đây là những người đã thêm bạn làm người bảo vệ. Bạn sẽ nhận được thông báo SOS khi họ gặp nguy hiểm.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4)),
        ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isAccepted ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Text(
                    firstLetter, 
                    style: TextStyle(color: isAccepted ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(phone, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      if (isAccepted)
                        Row(children: const [Icon(Icons.shield, size: 14, color: Colors.green), SizedBox(width: 4), Text("Đang bảo vệ", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))])
                      else
                        const Text("Đang chờ bạn xác nhận", style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            
            // Nếu chưa chấp nhận (PENDING) -> Hiển thị nút Chấp nhận / Từ chối
            if (!isAccepted) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleResponse(guardianId, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey, side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text("Từ chối"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleResponse(guardianId, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
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