class UnknownFace {
  final int id;
  final DateTime timestamp;
  final String? photoUrl;
  final double confidence;
  final bool isNotified;
  final String? notes;

  UnknownFace({
    required this.id,
    required this.timestamp,
    this.photoUrl,
    required this.confidence,
    this.isNotified = false,
    this.notes,
  });

  factory UnknownFace.fromJson(Map<String, dynamic> json) {
    return UnknownFace(
      id: json['id'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      photoUrl: json['photo_url'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isNotified: json['is_notified'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'photo_url': photoUrl,
      'confidence': confidence,
      'is_notified': isNotified,
      'notes': notes,
    };
  }
}