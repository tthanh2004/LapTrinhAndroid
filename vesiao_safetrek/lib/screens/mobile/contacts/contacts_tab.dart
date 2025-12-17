import 'package:flutter/material.dart';
import '../../../common/constants.dart'; 
import '../../../widgets/custom_header.dart';

// --- Model Contact ---
class Contact {
  final String id;
  final String name;
  final String phone;
  final String status; // 'pending' hoặc 'accepted'

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.status = 'pending',
  });
}

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  // 2. State quản lý danh sách danh bạ (Đã thêm dữ liệu mẫu để test hiển thị)
  final List<Contact> _contacts = [
    Contact(id: '1', name: 'Mẹ', phone: '0912345678', status: 'accepted'),
    Contact(id: '2', name: 'Bạn Thân - Linh', phone: '0987654321', status: 'pending'),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addContact() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      setState(() {
        // Giới hạn tối đa 5 người (Logic ví dụ)
        if (_contacts.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bạn chỉ được thêm tối đa 5 người bảo vệ")),
          );
          return;
        }

        _contacts.add(Contact(
          id: DateTime.now().toString(),
          name: _nameController.text,
          phone: _phoneController.text,
          status: 'pending',
        ));
      });
      
      _nameController.clear();
      _phoneController.clear();
      Navigator.pop(context); // Đóng modal
    }
  }

  void _removeContact(String id) {
    setState(() {
      _contacts.removeWhere((contact) => contact.id == id);
    });
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
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
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Số điện thoại",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  "Người này sẽ nhận được lời mời qua SMS và phải chấp nhận để trở thành người bảo vệ",
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Gửi lời mời"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    _nameController.clear();
                    _phoneController.clear();
                    Navigator.pop(context);
                  },
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
        // Header cập nhật động số lượng contact
        CustomHeader(
          title: "Danh bạ khẩn cấp", 
          subtitle: "${_contacts.length}/5 người bảo vệ", 
          icon: Icons.people_outline, 
          height: 160
        ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: kPrimaryLight, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: Colors.blue.shade100)
                ),
                child: const Text(
                  "Đây là những người sẽ nhận được cảnh báo khẩn cấp khi bạn gặp nguy hiểm.", 
                  style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13)
                ),
              ),
              const SizedBox(height: 20),
              
              // --- SỬA LỖI CHÍNH TẠI ĐÂY ---
              // Sử dụng toán tử spread (...) và map để hiển thị danh sách động
              if (_contacts.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Chưa có người bảo vệ nào", style: TextStyle(color: Colors.grey)),
                ))
              else
                ..._contacts.map((contact) => _buildContactItem(contact)),
              // -----------------------------

              const SizedBox(height: 20),
              SizedBox(
                height: 50, width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddModal(context), // Gọi hàm hiển thị Modal
                  icon: const Icon(Icons.add), 
                  label: const Text("Thêm người bảo vệ"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, 
                    foregroundColor: Colors.white
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(Contact contact) {
    bool isAccepted = contact.status == 'accepted';

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
              backgroundColor: Colors.blue.shade100,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "?",
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(contact.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
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
                          color: isAccepted ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAccepted ? "Đã chấp nhận" : "Chờ xác nhận",
                          style: TextStyle(
                            color: isAccepted ? Colors.green.shade700 : Colors.orange.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeContact(contact.id),
            ),
          ],
        ),
      ),
    );
  }
}