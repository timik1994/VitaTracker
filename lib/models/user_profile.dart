class UserProfile {
  final String? id;
  final String email;
  final String? name;
  final String? photoUrl;
  final int? age;
  final int? height; // в сантиметрах
  final double? weight; // в килограммах
  final String? gender;

  UserProfile({
    this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.age,
    this.height,
    this.weight,
    this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String?,
      email: map['email'] as String,
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
      age: map['age'] as int?,
      height: map['height'] as int?,
      weight: map['weight'] as double?,
      gender: map['gender'] as String?,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    int? age,
    int? height,
    double? weight,
    String? gender,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
    );
  }
} 