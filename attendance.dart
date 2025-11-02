class Attendance {
  final int id;
  final String employeeId;
  final String employeeName;
  final DateTime timestamp;
  final double confidence;
  final String? photoUrl;
  final bool isSynced;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.timestamp,
    required this.confidence,
    this.photoUrl,
    this.isSynced = true,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      photoUrl: json['photo_url'],
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'photo_url': photoUrl,
      'is_synced': isSynced,
    };
  }

  // Pour SQLite local
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'photo_url': photoUrl,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      employeeId: map['employee_id'],
      employeeName: map['employee_name'],
      timestamp: DateTime.parse(map['timestamp']),
      confidence: map['confidence'],
      photoUrl: map['photo_url'],
      isSynced: map['is_synced'] == 1,
    );
  }
}