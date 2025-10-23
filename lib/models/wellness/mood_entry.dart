import 'package:flutter/material.dart';

enum MoodLevel {
  energized,
  balanced,
  focused,
  tired,
  stressed,
}

extension MoodLevelPresentation on MoodLevel {
  String get label {
    switch (this) {
      case MoodLevel.energized:
        return 'Energizado(a)';
      case MoodLevel.balanced:
        return 'Equilibrado(a)';
      case MoodLevel.focused:
        return 'Focado(a)';
      case MoodLevel.tired:
        return 'Cansado(a)';
      case MoodLevel.stressed:
        return 'Estressado(a)';
    }
  }

  IconData get icon {
    switch (this) {
      case MoodLevel.energized:
        return Icons.bolt_rounded;
      case MoodLevel.balanced:
        return Icons.self_improvement_outlined;
      case MoodLevel.focused:
        return Icons.center_focus_strong_outlined;
      case MoodLevel.tired:
        return Icons.nightlight_round;
      case MoodLevel.stressed:
        return Icons.thunderstorm_outlined;
    }
  }

  Color tone(ColorScheme colorScheme) {
    switch (this) {
      case MoodLevel.energized:
        return colorScheme.primary;
      case MoodLevel.balanced:
        return colorScheme.tertiary;
      case MoodLevel.focused:
        return colorScheme.secondary;
      case MoodLevel.tired:
        return colorScheme.outlineVariant;
      case MoodLevel.stressed:
        return colorScheme.error;
    }
  }
}

class MoodEntry {
  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
  });

  final String id;
  final DateTime date;
  final MoodLevel mood;
  final String? note;

  MoodEntry copyWith({
    String? id,
    DateTime? date,
    MoodLevel? mood,
    String? note,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood.name,
      'note': note,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    final rawMood = json['mood'] as String?;
    final mood = MoodLevel.values.firstWhere(
      (level) => level.name == rawMood,
      orElse: () => MoodLevel.balanced,
    );
    final rawDate = json['date'] as String?;
    final parsedDate = rawDate == null
        ? DateTime.now()
        : DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now();

    return MoodEntry(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      date: parsedDate,
      mood: mood,
      note: json['note'] as String?,
    );
  }
}
