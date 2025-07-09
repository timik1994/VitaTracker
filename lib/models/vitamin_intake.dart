class VitaminIntake {
  final int? id;
  final int vitaminId;
  final DateTime scheduledTime;
  final DateTime takenTime;
  final bool isTaken;
  final String? name;

  VitaminIntake({
    this.id,
    required this.vitaminId,
    required this.scheduledTime,
    required this.takenTime,
    required this.isTaken,
    this.name,
  });

  Map<String, dynamic> toMap({bool forCloud = false}) {
    final map = {
      'id': id,
      'vitamin_id': vitaminId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime.toIso8601String(),
      'is_taken': isTaken ? 1 : 0,
    };
    if (forCloud && name != null) {
      map['name'] = name;
    }
    return map;
  }

  factory VitaminIntake.fromMap(Map<String, dynamic> map) {
    return VitaminIntake(
      id: map['id'] as int?,
      vitaminId: map['vitamin_id'] as int,
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      takenTime: DateTime.parse(map['taken_time'] as String),
      isTaken: map['is_taken'] == 1,
      name: map['name'] as String?,
    );
  }

  VitaminIntake copyWith({
    int? id,
    int? vitaminId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    bool? isTaken,
    String? name,
  }) {
    return VitaminIntake(
      id: id ?? this.id,
      vitaminId: vitaminId ?? this.vitaminId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      isTaken: isTaken ?? this.isTaken,
      name: name ?? this.name,
    );
  }
} 