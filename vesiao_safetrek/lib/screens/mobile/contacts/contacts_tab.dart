import 'package:flutter/material.dart';
import '../../../common/constants.dart';
import '../../../widgets/custom_header.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomHeader(title: "Danh bạ khẩn cấp", subtitle: "2/5 người bảo vệ", icon: Icons.people_outline, height: 160),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
                child: const Text("Đây là những người sẽ nhận được cảnh báo khẩn cấp khi bạn gặp nguy hiểm.", style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13)),
              ),
              const SizedBox(height: 20),
              _buildContact("Mẹ", "0912345678", "M"),
              _buildContact("Bạn Thân - Linh", "0987654321", "B"),
              const SizedBox(height: 20),
              SizedBox(
                height: 50, width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {}, icon: const Icon(Icons.add), label: const Text("Thêm người bảo vệ"),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContact(String name, String phone, String initial) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: kPrimaryLight, child: Text(initial, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold))),
        title: Text(name),
        subtitle: Text(phone),
        trailing: const Icon(Icons.delete_outline, color: Colors.red),
      ),
    );
  }
}