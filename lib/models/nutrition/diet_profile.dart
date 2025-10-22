import 'package:flutter/foundation.dart';

enum DietGoal { loseWeight, gainMass, maintain, reeducate }

extension DietGoalLabel on DietGoal {
  String get label {
    switch (this) {
      case DietGoal.loseWeight:
        return 'Perder peso';
      case DietGoal.gainMass:
        return 'Ganhar massa';
      case DietGoal.maintain:
        return 'Manter peso';
      case DietGoal.reeducate:
        return 'Reeducação alimentar';
    }
  }

  String get promptKeyword {
    switch (this) {
      case DietGoal.loseWeight:
        return 'cutting controlado';
      case DietGoal.gainMass:
        return 'ganho de massa muscular saudável';
      case DietGoal.maintain:
        return 'manutenção equilibrada';
      case DietGoal.reeducate:
        return 'reeducação e variedade';
    }
  }
}

enum DietPlanInterval { weekly, monthly }

extension DietPlanIntervalLabel on DietPlanInterval {
  String get label => this == DietPlanInterval.weekly ? 'Semanal' : 'Mensal';

  Duration get duration =>
      this == DietPlanInterval.weekly ? const Duration(days: 7) : const Duration(days: 30);
}

enum DietActivityLevel { sedentary, light, moderate, intense }

extension DietActivityLevelLabel on DietActivityLevel {
  String get label {
    switch (this) {
      case DietActivityLevel.sedentary:
        return 'Sedentário';
      case DietActivityLevel.light:
        return 'Leve (1-2x por semana)';
      case DietActivityLevel.moderate:
        return 'Moderado (3-4x por semana)';
      case DietActivityLevel.intense:
        return 'Intenso (5x ou mais por semana)';
    }
  }
}

enum DietCookingStyle { cookDaily, batchAndFreeze }

extension DietCookingStyleLabel on DietCookingStyle {
  String get label =>
      this == DietCookingStyle.cookDaily ? 'Cozinhar todos os dias' : 'Produzir e congelar';
}

enum DietSleepWindow { early, regular, late }

extension DietSleepWindowLabel on DietSleepWindow {
  String get label {
    switch (this) {
      case DietSleepWindow.early:
        return 'Dormir cedo (21h30)';
      case DietSleepWindow.regular:
        return 'Dormir no horário padrão (22h30)';
      case DietSleepWindow.late:
        return 'Dormir mais tarde (23h30)';
    }
  }

  int get targetHour {
    switch (this) {
      case DietSleepWindow.early:
        return 21;
      case DietSleepWindow.regular:
        return 22;
      case DietSleepWindow.late:
        return 23;
    }
  }

  int get targetMinute => 30;

  String get summary {
    switch (this) {
      case DietSleepWindow.early:
        return 'Ideal para quem prefere acordar cedo e ter uma rotina matinal produtiva.';
      case DietSleepWindow.regular:
        return 'Mantém um ciclo equilibrado com cerca de 7-8 horas de sono.';
      case DietSleepWindow.late:
        return 'Respeita rotinas noturnas sem comprometer a recuperação.';
    }
  }
}

@immutable
class DietProfile {
  const DietProfile({
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.metabolicEase,
    required this.goal,
    required this.interval,
    required this.cookingStyle,
    this.prefersBrazilianCuisine = true,
    this.additionalNotes,
    this.prefersSeasonalProduce = false,
    this.snackFrequency = 'Moderado',
    this.hydrationCoachEnabled = true,
    this.mindfulBreaksEnabled = true,
    this.movementCoachEnabled = true,
    this.sunlightCoachEnabled = true,
    this.sleepCoachEnabled = true,
    this.sleepWindow = DietSleepWindow.regular,
    this.wellnessDigestEnabled = true,
  });

  final double heightCm;
  final double weightKg;
  final DietActivityLevel activityLevel;
  /// Escala de 0 (muito difícil de emagrecer) a 5 (metabolismo acelerado).
  final int metabolicEase;
  final DietGoal goal;
  final DietPlanInterval interval;
  final DietCookingStyle cookingStyle;
  final bool prefersBrazilianCuisine;
  final String? additionalNotes;
  final bool prefersSeasonalProduce;
  final String snackFrequency;
  final bool hydrationCoachEnabled;
  final bool mindfulBreaksEnabled;
  final bool movementCoachEnabled;
  final bool sunlightCoachEnabled;
  final bool sleepCoachEnabled;
  final DietSleepWindow sleepWindow;
  final bool wellnessDigestEnabled;

  double get bmi {
    final meters = heightCm / 100;
    if (meters <= 0) {
      return 0;
    }
    return double.parse((weightKg / (meters * meters)).toStringAsFixed(1));
  }

  bool get exercisesRegularly => activityLevel != DietActivityLevel.sedentary;
  bool get isBatchCooking => cookingStyle == DietCookingStyle.batchAndFreeze;

  String get metabolicProfileLabel {
    if (metabolicEase <= 1) {
      return 'Metabolismo lento';
    }
    if (metabolicEase >= 5) {
      return 'Metabolismo acelerado';
    }
    return 'Metabolismo equilibrado';
  }

  DietProfile copyWith({
    double? heightCm,
    double? weightKg,
    DietActivityLevel? activityLevel,
    int? metabolicEase,
    DietGoal? goal,
    DietPlanInterval? interval,
    DietCookingStyle? cookingStyle,
    bool? prefersBrazilianCuisine,
    String? additionalNotes,
    bool? prefersSeasonalProduce,
    String? snackFrequency,
    bool? hydrationCoachEnabled,
    bool? mindfulBreaksEnabled,
    bool? movementCoachEnabled,
    bool? sunlightCoachEnabled,
    bool? sleepCoachEnabled,
    DietSleepWindow? sleepWindow,
    bool? wellnessDigestEnabled,
  }) {
    return DietProfile(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      metabolicEase: metabolicEase ?? this.metabolicEase,
      goal: goal ?? this.goal,
      interval: interval ?? this.interval,
      cookingStyle: cookingStyle ?? this.cookingStyle,
      prefersBrazilianCuisine:
          prefersBrazilianCuisine ?? this.prefersBrazilianCuisine,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      prefersSeasonalProduce:
          prefersSeasonalProduce ?? this.prefersSeasonalProduce,
      snackFrequency: snackFrequency ?? this.snackFrequency,
      hydrationCoachEnabled:
          hydrationCoachEnabled ?? this.hydrationCoachEnabled,
      mindfulBreaksEnabled:
          mindfulBreaksEnabled ?? this.mindfulBreaksEnabled,
      movementCoachEnabled:
          movementCoachEnabled ?? this.movementCoachEnabled,
      sunlightCoachEnabled:
          sunlightCoachEnabled ?? this.sunlightCoachEnabled,
      sleepCoachEnabled: sleepCoachEnabled ?? this.sleepCoachEnabled,
      sleepWindow: sleepWindow ?? this.sleepWindow,
      wellnessDigestEnabled:
          wellnessDigestEnabled ?? this.wellnessDigestEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.name,
      'metabolicEase': metabolicEase,
      'goal': goal.name,
      'interval': interval.name,
      'cookingStyle': cookingStyle.name,
      'prefersBrazilianCuisine': prefersBrazilianCuisine,
      'additionalNotes': additionalNotes,
      'prefersSeasonalProduce': prefersSeasonalProduce,
      'snackFrequency': snackFrequency,
      'hydrationCoachEnabled': hydrationCoachEnabled,
      'mindfulBreaksEnabled': mindfulBreaksEnabled,
      'movementCoachEnabled': movementCoachEnabled,
      'sunlightCoachEnabled': sunlightCoachEnabled,
      'sleepCoachEnabled': sleepCoachEnabled,
      'sleepWindow': sleepWindow.name,
      'wellnessDigestEnabled': wellnessDigestEnabled,
    };
  }

  factory DietProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('O mapa de perfil nutricional não pode ser nulo.');
    }

    double _readDouble(dynamic value, double fallback) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }
      return fallback;
    }

    int _readInt(dynamic value, int fallback) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
      return fallback;
    }

    T _enumFromString<T>(Iterable<T> values, String? name, T fallback) {
      if (name == null) {
        return fallback;
      }
      for (final value in values) {
        if (value.toString().split('.').last == name) {
          return value;
        }
      }
      return fallback;
    }

    return DietProfile(
      heightCm: _readDouble(map['heightCm'], 0),
      weightKg: _readDouble(map['weightKg'], 0),
      activityLevel: _enumFromString(
        DietActivityLevel.values,
        map['activityLevel']?.toString(),
        DietActivityLevel.sedentary,
      ),
      metabolicEase: _readInt(map['metabolicEase'], 2).clamp(0, 5),
      goal: _enumFromString(
        DietGoal.values,
        map['goal']?.toString(),
        DietGoal.reeducate,
      ),
      interval: _enumFromString(
        DietPlanInterval.values,
        map['interval']?.toString(),
        DietPlanInterval.weekly,
      ),
      cookingStyle: _enumFromString(
        DietCookingStyle.values,
        map['cookingStyle']?.toString(),
        DietCookingStyle.cookDaily,
      ),
      prefersBrazilianCuisine:
          map['prefersBrazilianCuisine'] as bool? ?? true,
      additionalNotes: map['additionalNotes'] as String?,
      prefersSeasonalProduce:
          map['prefersSeasonalProduce'] as bool? ?? false,
      snackFrequency: map['snackFrequency'] as String? ?? 'Moderado',
      hydrationCoachEnabled: map['hydrationCoachEnabled'] as bool? ?? true,
      mindfulBreaksEnabled: map['mindfulBreaksEnabled'] as bool? ?? true,
      movementCoachEnabled: map['movementCoachEnabled'] as bool? ?? true,
      sunlightCoachEnabled: map['sunlightCoachEnabled'] as bool? ?? true,
      sleepCoachEnabled: map['sleepCoachEnabled'] as bool? ?? true,
      sleepWindow: _enumFromString(
        DietSleepWindow.values,
        map['sleepWindow'] as String?,
        DietSleepWindow.regular,
      ),
      wellnessDigestEnabled: map['wellnessDigestEnabled'] as bool? ?? true,
    );
  }
}
