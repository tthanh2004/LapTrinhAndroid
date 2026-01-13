class Trip {
  final int tripId;
  final int userId;
  final String status; // ACTIVE, COMPLETED_SAFE, DURESS_ENDED
  final int durationMinutes;
  final String? destinationName;
  final DateTime startTime;
  final DateTime? endTime;

  Trip({
    required this.tripId,
    required this.userId,
    required this.status,
    required this.durationMinutes,
    this.destinationName,
    required this.startTime,
    this.endTime,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'] ?? 0,
      userId: json['userId'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      durationMinutes: json['durationMinutes'] ?? 0,
      destinationName: json['destinationName'],
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
    );
  }
}