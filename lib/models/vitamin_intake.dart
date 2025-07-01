class VitaminIntake {
  final int? id;
  final int vitaminId;
  final DateTime scheduledTime;
  final DateTime takenTime;
  final bool isTaken;

  VitaminIntake({
    this.id,
    required this.vitaminId,
    required this.scheduledTime,
    required this.takenTime,
    required this.isTaken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vitamin_id': vitaminId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime.toIso8601String(),
      'is_taken': isTaken ? 1 : 0,
    };
  }

  factory VitaminIntake.fromMap(Map<String, dynamic> map) {
    return VitaminIntake(
      id: map['id'] as int,
      vitaminId: map['vitamin_id'] as int,
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      takenTime: DateTime.parse(map['taken_time'] as String),
      isTaken: map['is_taken'] == 1,
    );
  }
} 