import 'dart:async';
import 'package:flutter/material.dart';

class TripController extends ChangeNotifier {
  bool _isMonitoring = false;
  int _selectedMinutes = 15;
  int _timeLeftSeconds = 0;
  Timer? _timer;

  bool get isMonitoring => _isMonitoring;
  int get selectedMinutes => _selectedMinutes;
  int get timeLeftSeconds => _timeLeftSeconds;

  String get formattedTime {
    final mins = (_timeLeftSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_timeLeftSeconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }


  void setDuration(int minutes) {
    _selectedMinutes = minutes;
    notifyListeners();
  }

  void startTrip() {
    _isMonitoring = true;
    _timeLeftSeconds = _selectedMinutes * 60;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        _timeLeftSeconds--;
        notifyListeners();
      } else {
        stopTrip();
      }
    });
  }

  void stopTrip() {
    _isMonitoring = false;
    _timer?.cancel();
    notifyListeners();
  }

  bool verifyPin(String inputPin) {
    if (inputPin == "1234") {
      stopTrip();
      return true;
    }
    if (inputPin == "9119") {
      stopTrip();
      print(">>> ĐÃ GỬI BÁO ĐỘNG NGẦM (SILENT ALARM) <<<");
      return true;
    }
    return false;
  }
}