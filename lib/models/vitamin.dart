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
      id: map['id'] as int,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      color: map['color'] as int,
      dosage: map['dosage'] as double,
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
} 