import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/guardian_service.dart';
// [IMPORTANT] Import the Guardian model so Dart knows what the 'Guardian' type is
import '../../../../models/guardian_model.dart'; 
import 'protected_list_screen.dart'; 

class ContactsTab extends StatefulWidget {
  final int userId;

  const ContactsTab({super.key, required this.userId});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final GuardianService _guardianService = GuardianService();
  
  // Controller for Add Guardian Modal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // [FIX 1] Change List<dynamic> to List<Guardian> to enforce type safety
  List<Guardian> _contacts = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 1. Load guardians list
  Future<void> _loadGuardians() async {
    // Only show loading indicator on initial load or if list is empty
    if (_contacts.isEmpty) {
        if(mounted) setState(() => _isLoading = true);
    }
    
    // The service now returns List<Guardian> objects
    final data = await _guardianService.fetchGuardians(widget.userId);
    
    if (mounted) {
      setState(() {
        _contacts = data;
        _isLoading = false;
      });
    }
  }

  // 2. Add Guardian (Send Request)
  void _addContact() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    // Input Validation
    if (name.isEmpty) {
      _showError("Vui lòng nhập tên người bảo vệ");
      return;
    }
    if (phone.length < 10) {
      _showError("Số điện thoại không hợp lệ");
      return;
    }
    
    // Limit to 5 guardians
    if (_contacts.length >= 5) {
      _showError("Tối đa 5 người bảo vệ. Hãy xóa bớt trước.");
      return;
    }

    // Close modal before calling API to prevent UI lag
    Navigator.pop(context); 
    
    // Show temporary loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đang gửi lời mời..."), duration: Duration(seconds: 1)),
    );

    // Call API
    bool success = await _guardianService.addGuardian(widget.userId, name, phone);
    
    if (success) {
      _nameController.clear();
      _phoneController.clear();
      _loadGuardians(); // Reload list
      
      if (mounted) {
        showCustomSnackBar(
          context, 
          title: "Đã gửi lời mời thành công", 
          message: "Người bảo vệ sẽ nhận được thông báo."
        );
      }
    } else {
      _showError("Lỗi: Không thể thêm người này (Có thể họ chưa cài App hoặc SĐT sai).");
    }
  }

  // 3. Delete Guardian
  void _performDelete(int id) async {
    // Call API Delete
    bool success = await _guardianService.deleteGuardian(id);
    
    if (success) {
      _loadGuardians(); // Reload list
      if (mounted) {
        showCustomSnackBar(
          context, 
          title: "Đã xóa thành công", 
          message: "Danh bạ khẩn cấp đã được cập nhật."
        );
      }
    } else {
      _showError("Có lỗi xảy ra khi xóa.");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue Header
          _buildBlueHeader(),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGuardians,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      children: [
                        _buildInfoBox(),
                        const SizedBox(height: 20),

                        // Contact List
                        if (_contacts.isEmpty)
                          _buildEmptyState()
                        else
                          // [FIX 2] Pass the Guardian object directly
                          ..._contacts.map((contact) => _buildContactCard(contact)),

                        const SizedBox(height: 30),
                        
                        // Auxiliary Buttons
                        _buildViewProtectedListButton(),
                        const SizedBox(height: 16),
                        _buildAddButton(),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildBlueHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      color: const Color(0xFF2563EB), // Royal Blue
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
            "Đây là những người sẽ nhận được cảnh báo khẩn cấp (SOS) khi bạn gặp nguy hiểm. Họ cũng có thể theo dõi vị trí của bạn khi bạn bật 'Chia sẻ chuyến đi'.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  // [FIX 3] Accept Guardian object instead of dynamic
  Widget _buildContactCard(Guardian contact) {
    // [FIX 4] Use dot notation (.) instead of brackets ['']
    // Ensure these property names match your Guardian model exactly
    String name = contact.name.isNotEmpty ? contact.name : "Không tên";
    String phone = contact.phone.isNotEmpty ? contact.phone : "";
    
    // Check your model for the exact property name for status/id
    // Assuming standard naming based on previous context:
    String status = contact.status; 
    int id = contact.id; 

    bool isAccepted = status == 'ACCEPTED';
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Text(
              firstLetter,
              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                
                // Status Indicator
                if (isAccepted)
                  Row(
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                      SizedBox(width: 4),
                      Text("Đã kết nối", style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
                else
                  Row(
                    children: const [
                      Icon(Icons.access_time_filled, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text("Chờ xác nhận...", style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
              ],
            ),
          ),
          
          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmDialog(id),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            tooltip: "Xóa",
          ),
        ],
      ),
    );
  }

  Widget _buildViewProtectedListButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProtectedListScreen(userId: widget.userId)),
          );
        },
        icon: const Icon(Icons.shield_outlined, size: 20),
        label: const Text("Xem danh sách người tôi đang bảo vệ"),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFF2563EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: const Color(0xFF2563EB),
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

  // --- MODAL & DIALOG ---

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
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              decoration: InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.phone_outlined),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa người này khỏi danh sách bảo vệ không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- CLASS CUSTOM SNACKBAR ---
class CustomSnackBar extends StatelessWidget {
  final String title;
  final String message;

  const CustomSnackBar({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Green 500
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Color(0xFF10B981), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function
void showCustomSnackBar(BuildContext context, {required String title, required String message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: CustomSnackBar(title: title, message: message),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 16, right: 16
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}