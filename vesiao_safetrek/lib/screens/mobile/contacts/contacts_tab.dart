import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/constants.dart';
import '../../../widgets/custom_header.dart';
import '../../../services/guardian_service.dart'; // Đảm bảo bạn đã có file này

class ContactsTab extends StatefulWidget {
  final int userId; // Nhận userId từ MobileScreen truyền vào

  const ContactsTab({super.key, required this.userId});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final GuardianService _guardianService = GuardianService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  List<dynamic> _contacts = []; // Danh sách người bảo vệ thực tế từ API
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuardians(); // Tải dữ liệu ngay khi vào màn hình
  }

  // --- LOGIC: Tải dữ liệu từ Server ---
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

  // --- LOGIC: Gửi lời mời thêm người bảo vệ ---
  void _addContact() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isNotEmpty && phone.length >= 10) {
      if (_contacts.length >= 5) {
        _showSnackBar("Bạn chỉ được thêm tối đa 5 người bảo vệ", Colors.orange);
        return;
      }

      bool success = await _guardianService.addGuardian(widget.userId, name, phone);
      if (success) {
        _nameController.clear();
        _phoneController.clear();
        if (mounted) Navigator.pop(context); // Đóng Modal
        _loadGuardians(); // Tải lại danh sách
        _showNotification(
          title: "Đã gửi lời mời", 
          subtitle: "Người thân sẽ nhận được thông báo để xác nhận."
        );
      } else {
        _showSnackBar("Không thể thêm người bảo vệ. Vui lòng thử lại.", Colors.red);
      }
    }
  }

  // --- LOGIC: Xóa người bảo vệ ---
  void _performDelete(int id) async {
    bool success = await _guardianService.deleteGuardian(id);
    if (success) {
      _loadGuardians();
      _showNotification(title: "Đã xóa", subtitle: "Danh bạ khẩn cấp đã cập nhật.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomHeader(
          title: "Danh bạ khẩn cấp",
          subtitle: "${_contacts.length}/5 người bảo vệ",
          icon: Icons.people_outline,
          height: 160,
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : RefreshIndicator(
                onRefresh: _loadGuardians,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 20),
                    if (_contacts.isEmpty)
                      _buildEmptyState()
                    else
                      ..._contacts.map((contact) => _buildContactItem(contact)),
                    const SizedBox(height: 20),
                    _buildAddButton(),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: const Text(
        "Người bảo vệ cần cài app SafeTrek để nhận được cảnh báo khẩn cấp khi bạn gặp nguy hiểm.",
        style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text("Chưa có người bảo vệ nào", style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddModal(context),
        icon: const Icon(Icons.add),
        label: const Text("Thêm người bảo vệ"),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildContactItem(dynamic contact) {
    // Lưu ý: Key phải khớp với các trường trả về từ NestJS (guardianName, guardianPhone, status, guardianId)
    bool isAccepted = contact['status'] == 'ACCEPTED';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isAccepted ? Colors.green.shade50 : Colors.blue.shade50,
              child: Text(
                contact['guardianName'][0].toUpperCase(),
                style: TextStyle(
                  color: isAccepted ? Colors.green : kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact['guardianName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(contact['guardianPhone'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 4),
                  _buildStatusBadge(isAccepted),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(contact['guardianId'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isAccepted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAccepted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAccepted ? Icons.check_circle : Icons.access_time, 
            size: 12, 
            color: isAccepted ? Colors.green : Colors.orange
          ),
          const SizedBox(width: 4),
          Text(
            isAccepted ? "Đã chấp nhận" : "Chờ xác nhận",
            style: TextStyle(
              color: isAccepted ? Colors.green.shade700 : Colors.orange.shade700, 
              fontSize: 11, 
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS (Modals & SnackBar) ---

  void _showNotification({required String title, required String subtitle}) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), 
              borderRadius: BorderRadius.circular(12), 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry?.remove());
  }

  void _showDeleteConfirmDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa người bảo vệ?"),
        content: const Text("Bạn có chắc chắn muốn xóa người này khỏi danh sách?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(int.parse(id));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, 
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thêm người bảo vệ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Tên người bảo vệ", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _addContact,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                child: const Text("Gửi lời mời"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}