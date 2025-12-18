import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/constants.dart'; 
import '../../../widgets/custom_header.dart';
class Contact {
  final String id;
  final String name;
  final String phone;
  final String status;

  Contact({required this.id, required this.name, required this.phone, this.status = 'pending'});
}

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final List<Contact> _contacts = [
    Contact(id: '1', name: 'Mẹ', phone: '0912345678', status: 'accepted'),
    Contact(id: '2', name: 'Bạn Thân - Linh', phone: '0987654321', status: 'pending'),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // ... (Giữ nguyên các hàm _showNotification và _showDeleteConfirmDialog như cũ) ...

  void _showNotification({required String title, required String subtitle}) {
    // (Code giữ nguyên như phiên bản trước)
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                Container(margin: const EdgeInsets.only(top: 2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.check, color: Color(0xFF10B981), size: 14))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13))])),
                GestureDetector(onTap: () => overlayEntry?.remove(), child: const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.close, color: Colors.white, size: 20))),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () { if (overlayEntry != null && overlayEntry.mounted) overlayEntry.remove(); });
  }

  void _showDeleteConfirmDialog(String contactId) {
    // (Code giữ nguyên như phiên bản trước)
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white, elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 32)),
              const SizedBox(height: 20),
              const Text("Xóa người bảo vệ?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              const Text("Bạn có muốn xóa người bảo vệ này không?", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF7E6), foregroundColor: const Color(0xFF595959), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Không", style: TextStyle(fontWeight: FontWeight.bold))))),
                  const SizedBox(width: 15),
                  Expanded(child: SizedBox(height: 50, child: ElevatedButton(onPressed: () { Navigator.pop(context); _performDelete(contactId); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), shadowColor: Colors.red.withOpacity(0.4)), child: const Text("Có", style: TextStyle(fontWeight: FontWeight.bold))))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _performDelete(String id) {
    setState(() { _contacts.removeWhere((contact) => contact.id == id); });
    _showNotification(title: "Đã xóa người bảo vệ", subtitle: "Danh bạ khẩn cấp đã được cập nhật.");
  }

  // --- 2. LOGIC THÊM: Có Validate Số điện thoại ---
  void _addContact() {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isNotEmpty && phone.isNotEmpty) {
      // Validate: Kiểm tra độ dài số điện thoại (Ví dụ phải đủ 10 số)
      if (phone.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Số điện thoại không hợp lệ (phải đủ 10 số)"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (_contacts.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chỉ được thêm tối đa 5 người bảo vệ")));
        return;
      }

      setState(() {
        _contacts.add(Contact(id: DateTime.now().toString(), name: name, phone: phone, status: 'pending'));
      });
      
      _nameController.clear();
      _phoneController.clear();
      Navigator.pop(context);
      _showNotification(title: "Đã gửi lời mời thành công", subtitle: "Người bảo vệ sẽ nhận được thông báo.");
    }
  }

  // --- 3. MODAL UI: Cập nhật TextField Số điện thoại ---
  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thêm người bảo vệ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Tên (Ví dụ: Mẹ, Bạn thân...)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              
              // --- CẬP NHẬT TEXTFIELD SỐ ĐIỆN THOẠI TẠI ĐÂY ---
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number, // Bàn phím số
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Chỉ cho phép nhập số
                  LengthLimitingTextInputFormatter(10),   // Giới hạn đúng 10 ký tự
                ],
                decoration: InputDecoration(
                  labelText: "Số điện thoại",
                  counterText: "", // Ẩn bộ đếm ký tự (vd: 0/10) bên dưới nếu muốn gọn
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              // ------------------------------------------------
              
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Text("Người này sẽ nhận được lời mời qua SMS và phải chấp nhận để trở thành người bảo vệ", style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _addContact,
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("Gửi lời mời"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 50,
                child: TextButton(
                  onPressed: () { _nameController.clear(); _phoneController.clear(); Navigator.pop(context); },
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomHeader(title: "Danh bạ khẩn cấp", subtitle: "${_contacts.length}/5 người bảo vệ", icon: Icons.people_outline, height: 160),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)), child: const Text("Đây là những người sẽ nhận được cảnh báo khẩn cấp khi bạn gặp nguy hiểm.", style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
              const SizedBox(height: 20),
              if (_contacts.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Chưa có người bảo vệ nào", style: TextStyle(color: Colors.grey))))
              else
                ..._contacts.map((contact) => _buildContactItem(contact)),
              const SizedBox(height: 20),
              SizedBox(height: 50, width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showAddModal(context), icon: const Icon(Icons.add), label: const Text("Thêm người bảo vệ"), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(Contact contact) {
    bool isAccepted = contact.status == 'accepted';
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.blue.shade100, child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "?", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Row(children: [Icon(Icons.phone, size: 12, color: Colors.grey.shade600), const SizedBox(width: 4), Text(contact.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: isAccepted ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isAccepted ? Icons.check_circle : Icons.access_time, size: 12, color: isAccepted ? Colors.green : Colors.orange), const SizedBox(width: 4), Text(isAccepted ? "Đã chấp nhận" : "Chờ xác nhận", style: TextStyle(color: isAccepted ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w500))]),
                  )
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _showDeleteConfirmDialog(contact.id)),
          ],
        ),
      ),
    );
  }
}