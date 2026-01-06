import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/guardian_service.dart';

class ContactsTab extends StatefulWidget {
  final int userId;

  const ContactsTab({super.key, required this.userId});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final GuardianService _guardianService = GuardianService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<dynamic> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  Future<void> _loadGuardians() async {
    setState(() => _isLoading = true);
    final data = await _guardianService.fetchGuardians(widget.userId);
    if (mounted) {
      setState(() {
        _contacts = data;
        _isLoading = false;
      });
    }
  }

  void _addContact() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isNotEmpty && phone.length >= 10) {
      if (_contacts.length >= 5) {
        _showSnackBar("Tối đa 5 người bảo vệ", Colors.orange);
        return;
      }

      bool success = await _guardianService.addGuardian(widget.userId, name, phone);
      if (success) {
        _nameController.clear();
        _phoneController.clear();
        if (mounted) Navigator.pop(context);
        _loadGuardians();
        _showSnackBar("Đã gửi lời mời thành công", Colors.green);
      } else {
        _showSnackBar("Lỗi thêm người bảo vệ", Colors.red);
      }
    }
  }

  void _performDelete(int id) async {
    bool success = await _guardianService.deleteGuardian(id);
    if (success) {
      _loadGuardians();
      _showSnackBar("Đã xóa người bảo vệ", Colors.grey);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header Xanh (Giống hình)
          _buildBlueHeader(),
          
          // 2. Nội dung danh sách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGuardians,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      children: [
                        // Hộp thông tin (Giống hình)
                        _buildInfoBox(),
                        const SizedBox(height: 20),

                        // Danh sách người bảo vệ
                        if (_contacts.isEmpty)
                          _buildEmptyState()
                        else
                          ..._contacts.map((contact) => _buildContactCard(contact)),

                        const SizedBox(height: 20),
                        
                        // Nút Thêm người bảo vệ (Giống hình)
                        _buildAddButton(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildBlueHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      color: const Color(0xFF1D4ED8), // Màu xanh đậm giống hình
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people_alt_outlined, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                "Danh sách người đang bảo vệ",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              "${_contacts.length}/5 người đang bảo vệ",
              style: TextStyle(color: Colors.blue[100], fontSize: 14),
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
        color: const Color(0xFFEFF6FF), // Màu nền xanh nhạt (blue 50)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)), // Viền xanh nhạt
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Người đang bảo vệ là ai?",
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            "Đây là những người sẽ nhận được cảnh báo khẩn cấp khi người được bảo vệ gặp nguy hiểm. Họ sẽ nhận được vị trí GPS và thông tin di chuyển của người được bảo vệ.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(dynamic contact) {
    bool isAccepted = contact['status'] == 'ACCEPTED';
    String firstLetter = contact['guardianName'].isNotEmpty ? contact['guardianName'][0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar tròn xanh nhạt
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFDBEAFE), // Blue 100
              child: Text(
                firstLetter,
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['guardianName'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        contact['guardianPhone'],
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Trạng thái (Xanh lá cây)
                  if (isAccepted)
                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF22C55E)), // Green 500
                        SizedBox(width: 4),
                        Text(
                          "Đã chấp nhận",
                          style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: const [
                        Icon(Icons.access_time, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          "Chờ xác nhận",
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Nút xóa (Thùng rác đỏ)
            InkWell(
              onTap: () => _showDeleteConfirmDialog(contact['guardianId']),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)), // Red 500
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _showAddModal(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Màu xanh chủ đạo
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Thêm người bảo vệ",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.group_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Chưa có người bảo vệ nào", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // --- MODAL & DIALOGS ---

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            const Text("Thêm người bảo vệ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Họ sẽ nhận được lời mời kết nối.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Tên hiển thị (VD: Mẹ, Anh Hai)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Gửi lời mời", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa người bảo vệ?"),
        content: const Text("Người này sẽ không còn nhận được cảnh báo SOS của bạn nữa."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(id);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}