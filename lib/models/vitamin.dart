import 'package:flutter/material.dart';

class Vitamin {
  final int? id;
  final String name;
  final String abbreviation;
  final int color;
  final double dosage;
  final String unit;
  final String period;
  final String mealRelation;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> compatibleWith;
  final List<String> incompatibleWith;
  final String description;
  final String benefits;
  final String organs;
  final String dailyNorm;
  final String? bestTimeToTake;
  final String? form;

  Vitamin({
    this.id,
    required this.name,
    required this.abbreviation,
    required this.color,
    required this.dosage,
    required this.unit,
    required this.period,
    required this.mealRelation,
    required this.startDate,
    required this.endDate,
    this.compatibleWith = const [],
    this.incompatibleWith = const [],
    this.description = '',
    this.benefits = '',
    this.organs = '',
    this.dailyNorm = '',
    this.bestTimeToTake,
    this.form,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'color': color,
      'dosage': dosage,
      'unit': unit,
      'period': period,
      'meal_relation': mealRelation,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'compatible_with': compatibleWith.join(','),
      'incompatible_with': incompatibleWith.join(','),
      'description': description,
      'benefits': benefits,
      'organs': organs,
      'daily_norm': dailyNorm,
      'best_time_to_take': bestTimeToTake,
      'form': form,
    };
  }

  factory Vitamin.fromMap(Map<String, dynamic> map) {
    return Vitamin(
      id: map['id'] == null ? null : (map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString())),
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      color: map['color'] is int ? map['color'] as int : int.tryParse(map['color'].toString()) ?? 0,
      dosage: map['dosage'] is double ? map['dosage'] as double : (map['dosage'] is int ? (map['dosage'] as int).toDouble() : double.tryParse(map['dosage'].toString()) ?? 0),
      unit: map['unit'] as String,
      period: map['period'] as String,
      mealRelation: map['meal_relation'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      compatibleWith: (map['compatible_with'] as String?)?.split(',') ?? [],
      incompatibleWith: (map['incompatible_with'] as String?)?.split(',') ?? [],
      description: map['description'] as String? ?? '',
      benefits: map['benefits'] as String? ?? '',
      organs: map['organs'] as String? ?? '',
      dailyNorm: map['daily_norm'] as String? ?? '',
      bestTimeToTake: map['best_time_to_take'] as String?,
      form: map['form'],
    );
  }

  Vitamin copyWith({
    int? id,
    String? name,
    String? abbreviation,
    int? color,
    double? dosage,
    String? unit,
    String? period,
    String? mealRelation,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? compatibleWith,
    List<String>? incompatibleWith,
    String? description,
    String? benefits,
    String? organs,
    String? dailyNorm,
    String? bestTimeToTake,
    String? form,
  }) {
    return Vitamin(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      color: color ?? this.color,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      period: period ?? this.period,
      mealRelation: mealRelation ?? this.mealRelation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      compatibleWith: compatibleWith ?? this.compatibleWith,
      incompatibleWith: incompatibleWith ?? this.incompatibleWith,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      organs: organs ?? this.organs,
      dailyNorm: dailyNorm ?? this.dailyNorm,
      bestTimeToTake: bestTimeToTake ?? this.bestTimeToTake,
      form: form ?? this.form,
    );
  }
} 