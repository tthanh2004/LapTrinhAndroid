import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/guardian_service.dart';
import 'protected_list_screen.dart'; // Đảm bảo bạn đã có file này

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tối đa 5 người bảo vệ"), backgroundColor: Colors.orange),
        );
        return;
      }

      bool success = await _guardianService.addGuardian(widget.userId, name, phone);
      if (success) {
        _nameController.clear();
        _phoneController.clear();
        if (mounted) Navigator.pop(context);
        _loadGuardians();
        
        // [MỚI] Hiển thị thông báo đẹp chuẩn Figma
        if (mounted) {
          showCustomSnackBar(
            context, 
            title: "Đã gửi lời mời thành công", 
            message: "Người bảo vệ sẽ nhận được thông báo."
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi thêm người bảo vệ"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _performDelete(int id) async {
    bool success = await _guardianService.deleteGuardian(id);
    if (success) {
      _loadGuardians();
      // [MỚI] Hiển thị thông báo đẹp chuẩn Figma
      if (mounted) {
        showCustomSnackBar(
          context, 
          title: "Đã xóa người bảo vệ", 
          message: "Danh bạ khẩn cấp đã được cập nhật."
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header Xanh
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
                        // Hộp thông tin
                        _buildInfoBox(),
                        const SizedBox(height: 20),

                        // Danh sách người bảo vệ (contacts)
                        if (_contacts.isEmpty)
                          _buildEmptyState()
                        else
                          ..._contacts.map((contact) => _buildContactCard(contact)),

                        const SizedBox(height: 30),
                        
                        // Nút xem danh sách người ĐANG BẢO VỆ (Màu nhạt)
                        _buildViewProtectedListButton(),

                        const SizedBox(height: 16),

                        // Nút Thêm người bảo vệ (Màu đậm)
                        _buildAddButton(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS GIAO DIỆN ---

  Widget _buildBlueHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      color: const Color(0xFF2563EB), // Màu xanh Royal Blue
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people_alt_outlined, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Danh sách người bảo vệ",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              "${_contacts.length}/5 người bảo vệ",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
        border: Border.all(color: const Color(0xFFDBEAFE)), // Blue 200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Người bảo vệ là ai?",
            style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 15),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFDBEAFE), // Blue 100
              child: Text(
                firstLetter,
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['guardianName'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
                          "Chờ xác nhận",
                          style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showDeleteConfirmDialog(contact['guardianId']),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewProtectedListButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProtectedListScreen(userId: widget.userId)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFF6FF), // Màu nền xanh rất nhạt
          foregroundColor: const Color(0xFF2563EB), // Chữ màu xanh đậm
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFDBEAFE)), // Viền nhẹ
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text(
              "Danh sách người được bảo vệ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => _showAddModal(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Màu xanh chủ đạo
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
          shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Thêm người bảo vệ",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  // --- MODALS & DIALOGS ---

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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF), // Blue 50
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                "Xóa người bảo vệ?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Bạn có muốn xóa người bảo vệ này không?",
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF7ED), 
                          foregroundColor: const Color(0xFF475569), 
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Không", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performDelete(id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444), 
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Có", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET CUSTOM SNACKBAR (Bạn có thể tách ra file riêng hoặc để ở đây) ---
class CustomSnackBar extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback? onClose;

  const CustomSnackBar({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Màu xanh lá chuẩn Figma (Green 500)
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon check tròn trắng
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF10B981), size: 14),
          ),
          const SizedBox(width: 12),
          
          // Nội dung text
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Nút X đóng
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}

// Hàm tiện ích để gọi nhanh SnackBar này
void showCustomSnackBar(BuildContext context, {required String title, required String message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: CustomSnackBar(title: title, message: message),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 160, // Hiển thị ở trên cùng (cách top một khoảng)
        left: 16,
        right: 16,
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}