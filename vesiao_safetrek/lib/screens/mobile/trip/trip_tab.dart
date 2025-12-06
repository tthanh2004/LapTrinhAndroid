import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/constants.dart';
import '../../../controllers/trip_controller.dart';
import '../../../widgets/custom_header.dart';
import '../../../widgets/pin_pad.dart';

class TripTab extends StatelessWidget {
  const TripTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng Consumer để lắng nghe TripController
    return Consumer<TripController>(
      builder: (context, controller, child) {
        // Nếu đang đi -> Hiện Active View, ngược lại hiện Setup View
        return controller.isMonitoring 
            ? _buildActiveView(context, controller) 
            : _buildSetupView(context, controller);
      },
    );
  }

  // View 1: Cài đặt chuyến đi
  Widget _buildSetupView(BuildContext context, TripController controller) {
    return Column(
      children: [
        const CustomHeader(title: "Cài đặt chuyến đi", subtitle: "Thiết lập giám sát an toàn", icon: Icons.security, height: 150),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Info Box
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
                child: Row(children: const [
                    Icon(Icons.shield_outlined, color: kPrimaryColor),
                    SizedBox(width: 10),
                    Expanded(child: Text("Hệ thống sẽ tự động gửi cảnh báo nếu bạn không xác nhận an toàn.", style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 25),
              
              const TextField(decoration: InputDecoration(labelText: "Điểm đến (Tùy chọn)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 20),
              
              TextField(
                controller: TextEditingController(text: controller.selectedMinutes.toString()),
                decoration: const InputDecoration(labelText: "Thời gian (phút)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer_outlined)),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              
              // Chips chọn nhanh
              Wrap(spacing: 10, children: [5, 10, 15, 30, 60].map((m) {
                final isSelected = controller.selectedMinutes == m;
                return ChoiceChip(
                  label: Text("$m phút"),
                  selected: isSelected,
                  onSelected: (_) => controller.setDuration(m),
                  selectedColor: kPrimaryColor,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                );
              }).toList()),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => controller.startTrip(),
                  icon: const Icon(Icons.shield_outlined), label: const Text("Bắt đầu giám sát"),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // View 2: Đang giám sát (Đếm ngược)
  Widget _buildActiveView(BuildContext context, TripController controller) {
    return Column(
      children: [
        const CustomHeader(title: "Đang giám sát", subtitle: "Đang chia sẻ vị trí...", icon: Icons.radar, height: 140),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Đồng hồ tròn
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: 1, strokeWidth: 15, color: Colors.grey.shade200)),
                  SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: 0.7, strokeWidth: 15, color: kPrimaryColor)),
                  Column(children: [
                    Text(controller.formattedTime, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const Text("còn lại", style: TextStyle(color: kSubTextColor)),
                  ]),
                ],
              ),
              const SizedBox(height: 50),
              
              // Nút xác nhận an toàn
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                        builder: (_) => PinPad(onPinSubmit: (pin) {
                          Navigator.pop(context);
                          if (!controller.verifyPin(pin)) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sai mã PIN!")));
                          }
                        }),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline), label: const Text("Tôi đã an toàn"),
                    style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor, foregroundColor: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}