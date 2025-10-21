import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'diet_profile.dart';

@immutable
class DietPlanTargets {
  const DietPlanTargets({
    required this.caloriesPerDay,
    required this.carbsPercentage,
    required this.proteinPercentage,
    required this.fatPercentage,
  });

  final int caloriesPerDay;
  final double carbsPercentage;
  final double proteinPercentage;
  final double fatPercentage;

  double get _totalPercentage =>
      carbsPercentage + proteinPercentage + fatPercentage;

  DietPlanTargets copyWith({
    int? caloriesPerDay,
    double? carbsPercentage,
    double? proteinPercentage,
    double? fatPercentage,
  }) {
    return DietPlanTargets(
      caloriesPerDay: caloriesPerDay ?? this.caloriesPerDay,
      carbsPercentage: carbsPercentage ?? this.carbsPercentage,
      proteinPercentage: proteinPercentage ?? this.proteinPercentage,
      fatPercentage: fatPercentage ?? this.fatPercentage,
    );
  }

  DietPlanTargets normalized() {
    if (_totalPercentage <= 0) {
      return this;
    }
    final ratio = 100 / _totalPercentage;
    return DietPlanTargets(
      caloriesPerDay: caloriesPerDay,
      carbsPercentage: double.parse((carbsPercentage * ratio).toStringAsFixed(1)),
      proteinPercentage:
          double.parse((proteinPercentage * ratio).toStringAsFixed(1)),
      fatPercentage: double.parse((fatPercentage * ratio).toStringAsFixed(1)),
    );
  }

  Map<String, double> macroGrams() {
    if (caloriesPerDay <= 0) {
      return const <String, double>{
        'carbs': 0,
        'proteins': 0,
        'fats': 0,
      };
    }
    final carbsCalories = caloriesPerDay * (carbsPercentage / 100);
    final proteinCalories = caloriesPerDay * (proteinPercentage / 100);
    final fatCalories = caloriesPerDay * (fatPercentage / 100);
    return <String, double>{
      'carbs': double.parse((carbsCalories / 4).toStringAsFixed(1)),
      'proteins': double.parse((proteinCalories / 4).toStringAsFixed(1)),
      'fats': double.parse((fatCalories / 9).toStringAsFixed(1)),
    };
  }

  factory DietPlanTargets.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const DietPlanTargets(
        caloriesPerDay: 1800,
        carbsPercentage: 45,
        proteinPercentage: 30,
        fatPercentage: 25,
      );
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

    return DietPlanTargets(
      caloriesPerDay: _readInt(map['caloriesPerDay'], 1800),
      carbsPercentage: _readDouble(map['carbs'], 45),
      proteinPercentage: _readDouble(map['proteins'], 30),
      fatPercentage: _readDouble(map['fats'], 25),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'caloriesPerDay': caloriesPerDay,
      'carbs': carbsPercentage,
      'proteins': proteinPercentage,
      'fats': fatPercentage,
    };
  }
}

@immutable
class HydrationReminderSlot {
  const HydrationReminderSlot({
    required this.hour,
    required this.minute,
    required this.amountMl,
    required this.label,
  });

  final int hour;
  final int minute;
  final int amountMl;
  final String label;

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hour': hour,
      'minute': minute,
      'amountMl': amountMl,
      'label': label,
    };
  }

  factory HydrationReminderSlot.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const HydrationReminderSlot(
        hour: 8,
        minute: 0,
        amountMl: 300,
        label: '08:00 - 300 ml',
      );
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

    return HydrationReminderSlot(
      hour: _readInt(map['hour'], 8).clamp(0, 23),
      minute: _readInt(map['minute'], 0).clamp(0, 59),
      amountMl: _readInt(map['amountMl'], 300).clamp(50, 1000),
      label: _readString(map['label']) ?? 'Hidrate-se',
    );
  }
}

@immutable
class HydrationPlanInfo {
  const HydrationPlanInfo({
    required this.totalMl,
    required this.tip,
    required this.reminders,
  });

  final int totalMl;
  final String tip;
  final List<HydrationReminderSlot> reminders;

  double get liters => double.parse((totalMl / 1000).toStringAsFixed(2));
  bool get hasReminders => reminders.isNotEmpty;

  HydrationPlanInfo copyWith({
    int? totalMl,
    String? tip,
    List<HydrationReminderSlot>? reminders,
  }) {
    return HydrationPlanInfo(
      totalMl: totalMl ?? this.totalMl,
      tip: tip ?? this.tip,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalMl': totalMl,
      'tip': tip,
      'reminders': reminders.map((slot) => slot.toMap()).toList(),
    };
  }

  factory HydrationPlanInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const HydrationPlanInfo(
        totalMl: 2000,
        tip: 'Beba pelo menos oito copos de água ao longo do dia.',
        reminders: <HydrationReminderSlot>[],
      );
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

    final rawReminders = map['reminders'];
    final reminders = rawReminders is Iterable
        ? rawReminders
            .map((dynamic item) =>
                HydrationReminderSlot.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <HydrationReminderSlot>[];

    return HydrationPlanInfo(
      totalMl: _readInt(map['totalMl'], 2000).clamp(1000, 5000),
      tip: _readString(map['tip']) ??
          'Hidrate-se de forma consistente durante o dia.',
      reminders: List<HydrationReminderSlot>.unmodifiable(reminders),
    );
  }
}

class SleepRoutineInfo {
  const SleepRoutineInfo({
    required this.enabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.message,
    required this.windDownSummary,
    required this.windDownTips,
  });

  final bool enabled;
  final int reminderHour;
  final int reminderMinute;
  final String message;
  final String windDownSummary;
  final List<String> windDownTips;

  bool get hasReminder => enabled && message.trim().isNotEmpty;

  SleepRoutineInfo copyWith({
    bool? enabled,
    int? reminderHour,
    int? reminderMinute,
    String? message,
    String? windDownSummary,
    List<String>? windDownTips,
  }) {
    return SleepRoutineInfo(
      enabled: enabled ?? this.enabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      message: message ?? this.message,
      windDownSummary: windDownSummary ?? this.windDownSummary,
      windDownTips: windDownTips ?? this.windDownTips,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'message': message,
      'windDownSummary': windDownSummary,
      'windDownTips': windDownTips,
    };
  }

  factory SleepRoutineInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const SleepRoutineInfo(
        enabled: false,
        reminderHour: 22,
        reminderMinute: 0,
        message: '',
        windDownSummary: '',
        windDownTips: <String>[],
      );
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

    return SleepRoutineInfo(
      enabled: map['enabled'] as bool? ?? false,
      reminderHour: _readInt(map['reminderHour'], 22).clamp(0, 23),
      reminderMinute: _readInt(map['reminderMinute'], 0).clamp(0, 59),
      message: _readString(map['message']) ?? '',
      windDownSummary: _readString(map['windDownSummary']) ?? '',
      windDownTips: _readStringList(map['windDownTips']),
    );
  }
}

class WellnessDigestInfo {
  const WellnessDigestInfo({
    required this.enabled,
    required this.summary,
    required this.highlights,
    required this.callToAction,
    required this.hoursBeforeCheckIn,
  });

  final bool enabled;
  final String summary;
  final List<String> highlights;
  final String callToAction;
  final int hoursBeforeCheckIn;

  bool get hasHighlights => highlights.isNotEmpty;

  WellnessDigestInfo copyWith({
    bool? enabled,
    String? summary,
    List<String>? highlights,
    String? callToAction,
    int? hoursBeforeCheckIn,
  }) {
    return WellnessDigestInfo(
      enabled: enabled ?? this.enabled,
      summary: summary ?? this.summary,
      highlights: highlights ?? this.highlights,
      callToAction: callToAction ?? this.callToAction,
      hoursBeforeCheckIn: hoursBeforeCheckIn ?? this.hoursBeforeCheckIn,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'summary': summary,
      'highlights': highlights,
      'callToAction': callToAction,
      'hoursBeforeCheckIn': hoursBeforeCheckIn,
    };
  }

  factory WellnessDigestInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const WellnessDigestInfo(
        enabled: false,
        summary: '',
        highlights: <String>[],
        callToAction: '',
        hoursBeforeCheckIn: 12,
      );
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

    return WellnessDigestInfo(
      enabled: map['enabled'] as bool? ?? false,
      summary: _readString(map['summary']) ?? '',
      highlights: _readStringList(map['highlights']),
      callToAction: _readString(map['callToAction']) ?? '',
      hoursBeforeCheckIn:
          _readInt(map['hoursBeforeCheckIn'], 12).clamp(1, 48),
    );
  }
}

@immutable
class MovementBreakSlot {
  const MovementBreakSlot({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    required this.activity,
  });

  final int hour;
  final int minute;
  final int durationMinutes;
  final String activity;

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hour': hour,
      'minute': minute,
      'durationMinutes': durationMinutes,
      'activity': activity,
    };
  }

  factory MovementBreakSlot.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const MovementBreakSlot(
        hour: 10,
        minute: 30,
        durationMinutes: 5,
        activity: 'Alongamento leve para pescoço e ombros',
      );
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

    return MovementBreakSlot(
      hour: _readInt(map['hour'], 10).clamp(0, 23),
      minute: _readInt(map['minute'], 30).clamp(0, 59),
      durationMinutes:
          _readInt(map['durationMinutes'], 5).clamp(2, 20),
      activity: _readString(map['activity']) ??
          'Pausa ativa para alongar e respirar conscientemente',
    );
  }
}

@immutable
class MovementBreakInfo {
  const MovementBreakInfo({
    required this.enabled,
    required this.summary,
    required this.slots,
    required this.tips,
  });

  final bool enabled;
  final String summary;
  final List<MovementBreakSlot> slots;
  final List<String> tips;

  bool get hasReminders => enabled && slots.isNotEmpty;

  MovementBreakInfo copyWith({
    bool? enabled,
    String? summary,
    List<MovementBreakSlot>? slots,
    List<String>? tips,
  }) {
    return MovementBreakInfo(
      enabled: enabled ?? this.enabled,
      summary: summary ?? this.summary,
      slots: slots ?? this.slots,
      tips: tips ?? this.tips,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'summary': summary,
      'slots': slots.map((slot) => slot.toMap()).toList(),
      'tips': tips,
    };
  }

  factory MovementBreakInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const MovementBreakInfo(
        enabled: false,
        summary: '',
        slots: <MovementBreakSlot>[],
        tips: <String>[],
      );
    }

    final rawSlots = map['slots'];
    final slots = rawSlots is Iterable
        ? rawSlots
            .map((dynamic item) =>
                MovementBreakSlot.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <MovementBreakSlot>[];

    return MovementBreakInfo(
      enabled: map['enabled'] as bool? ?? false,
      summary: _readString(map['summary']) ?? '',
      slots: List<MovementBreakSlot>.unmodifiable(slots),
      tips: _readStringList(map['tips']),
    );
  }
}

@immutable
class SunlightExposureInfo {
  const SunlightExposureInfo({
    required this.enabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.durationMinutes,
    required this.message,
    required this.benefits,
    required this.cautions,
  });

  final bool enabled;
  final int reminderHour;
  final int reminderMinute;
  final int durationMinutes;
  final String message;
  final List<String> benefits;
  final List<String> cautions;

  bool get hasReminder => enabled && message.trim().isNotEmpty;

  SunlightExposureInfo copyWith({
    bool? enabled,
    int? reminderHour,
    int? reminderMinute,
    int? durationMinutes,
    String? message,
    List<String>? benefits,
    List<String>? cautions,
  }) {
    return SunlightExposureInfo(
      enabled: enabled ?? this.enabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      message: message ?? this.message,
      benefits: benefits ?? this.benefits,
      cautions: cautions ?? this.cautions,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'durationMinutes': durationMinutes,
      'message': message,
      'benefits': benefits,
      'cautions': cautions,
    };
  }

  factory SunlightExposureInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const SunlightExposureInfo(
        enabled: false,
        reminderHour: 9,
        reminderMinute: 0,
        durationMinutes: 15,
        message: '',
        benefits: <String>[],
        cautions: <String>[],
      );
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

    return SunlightExposureInfo(
      enabled: map['enabled'] as bool? ?? false,
      reminderHour: _readInt(map['reminderHour'], 9).clamp(0, 23),
      reminderMinute: _readInt(map['reminderMinute'], 0).clamp(0, 59),
      durationMinutes:
          _readInt(map['durationMinutes'], 15).clamp(5, 45),
      message: _readString(map['message']) ?? '',
      benefits: _readStringList(map['benefits']),
      cautions: _readStringList(map['cautions']),
    );
  }
}

@immutable
class DietPlanMeal {
  const DietPlanMeal({
    required this.name,
    required this.description,
    this.calories,
    this.macroFocus,
    this.prepNotes,
    this.ingredients = const <String>[],
    this.steps = const <String>[],
    this.difficulty,
    this.duration,
  });

  final String name;
  final String description;
  final int? calories;
  final String? macroFocus;
  final String? prepNotes;
  final List<String> ingredients;
  final List<String> steps;
  final String? difficulty;
  final String? duration;

  DietPlanMeal copyWith({
    String? name,
    String? description,
    int? calories,
    String? macroFocus,
    String? prepNotes,
    List<String>? ingredients,
    List<String>? steps,
    String? difficulty,
    String? duration,
  }) {
    return DietPlanMeal(
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      macroFocus: macroFocus ?? this.macroFocus,
      prepNotes: prepNotes ?? this.prepNotes,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
    );
  }

  factory DietPlanMeal.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const DietPlanMeal(
        name: 'Refeição',
        description:
            'A IA não forneceu detalhes para esta refeição. Ajuste manualmente.',
      );
    }

    int? _readInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    return DietPlanMeal(
      name: _readString(map['name']) ?? 'Refeição',
      description:
          _readString(map['description']) ?? 'Sem descrição fornecida pela IA.',
      calories: _readInt(map['calories']),
      macroFocus: _readString(map['macroFocus']),
      prepNotes: _readString(map['prepNotes']),
      ingredients: _readOrderedList(map['ingredients']),
      steps: _readOrderedList(map['steps']),
      difficulty: _readString(map['difficulty']),
      duration: _readString(map['duration']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'calories': calories,
      'macroFocus': macroFocus,
      'prepNotes': prepNotes,
      'ingredients': ingredients,
      'steps': steps,
      'difficulty': difficulty,
      'duration': duration,
    };
  }
}

@immutable
class DietPlanDay {
  const DietPlanDay({
    required this.label,
    required this.focus,
    required this.meals,
  });

  final String label;
  final String focus;
  final List<DietPlanMeal> meals;

  int? get totalCalories {
    var total = 0;
    var hasCalories = false;
    for (final meal in meals) {
      final value = meal.calories;
      if (value != null) {
        total += value;
        hasCalories = true;
      }
    }
    return hasCalories ? total : null;
  }

  DietPlanDay copyWith({
    String? label,
    String? focus,
    List<DietPlanMeal>? meals,
  }) {
    return DietPlanDay(
      label: label ?? this.label,
      focus: focus ?? this.focus,
      meals: meals ?? this.meals,
    );
  }

  factory DietPlanDay.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const DietPlanDay(
        label: 'Dia',
        focus: 'Equilíbrio nutricional',
        meals: <DietPlanMeal>[],
      );
    }

    final rawMeals = map['meals'];
    final meals = rawMeals is Iterable
        ? rawMeals
            .map((dynamic item) =>
                DietPlanMeal.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <DietPlanMeal>[];

    return DietPlanDay(
      label: _readString(map['label']) ?? 'Dia',
      focus: _readString(map['focus']) ?? 'Equilíbrio nutricional',
      meals: List<DietPlanMeal>.unmodifiable(meals),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'focus': focus,
      'meals': meals.map((meal) => meal.toMap()).toList(),
    };
  }
}

@immutable
class ShoppingListItem {
  const ShoppingListItem({
    required this.category,
    required this.item,
    required this.quantity,
    this.notes,
    this.alternatives = const <String>[],
    this.substitutionNote,
  });

  final String category;
  final String item;
  final String quantity;
  final String? notes;
  final List<String> alternatives;
  final String? substitutionNote;

  factory ShoppingListItem.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ShoppingListItem(
        category: 'Diversos',
        item: 'Ingrediente não especificado',
        quantity: '1 unidade',
      );
    }

    final rawAlternatives = map['alternatives'];
    final alternatives = rawAlternatives is Iterable
        ? rawAlternatives
            .map((dynamic value) => _readString(value) ?? '')
            .where((value) => value.trim().isNotEmpty)
            .map((value) => value.trim())
            .toList()
        : const <String>[];

    return ShoppingListItem(
      category: _readString(map['category']) ?? 'Diversos',
      item: _readString(map['item']) ?? 'Ingrediente não especificado',
      quantity: _readString(map['quantity']) ?? '1 unidade',
      notes: _readString(map['notes']),
      alternatives: List<String>.unmodifiable(alternatives),
      substitutionNote: _readString(map['substitutionNote']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'category': category,
      'item': item,
      'quantity': quantity,
      'notes': notes,
      'alternatives': alternatives,
      'substitutionNote': substitutionNote,
    };
  }

  ShoppingListItem copyWith({
    String? category,
    String? item,
    String? quantity,
    String? notes,
    List<String>? alternatives,
    String? substitutionNote,
  }) {
    return ShoppingListItem(
      category: category ?? this.category,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      alternatives: alternatives ?? this.alternatives,
      substitutionNote: substitutionNote ?? this.substitutionNote,
    );
  }
}

@immutable
class DietPlan {
  const DietPlan({
    required this.strategy,
    required this.targets,
    required this.hydrationGoal,
    required this.hydrationPlan,
    required this.highlights,
    required this.days,
    required this.shoppingList,
    required this.followUpTips,
    required this.mindfulBreakMessage,
    required this.mindfulBreakHour,
    required this.mindfulBreakMinute,
    required this.sleepRoutine,
    required this.wellnessDigest,
    required this.movementRoutine,
    required this.sunlightRoutine,
  });

  final String strategy;
  final DietPlanTargets targets;
  final String hydrationGoal;
  final HydrationPlanInfo hydrationPlan;
  final List<String> highlights;
  final List<DietPlanDay> days;
  final List<ShoppingListItem> shoppingList;
  final List<String> followUpTips;
  final String mindfulBreakMessage;
  final int mindfulBreakHour;
  final int mindfulBreakMinute;
  final SleepRoutineInfo sleepRoutine;
  final WellnessDigestInfo wellnessDigest;
  final MovementBreakInfo movementRoutine;
  final SunlightExposureInfo sunlightRoutine;

  DietPlan copyWith({
    String? strategy,
    DietPlanTargets? targets,
    String? hydrationGoal,
    HydrationPlanInfo? hydrationPlan,
    List<String>? highlights,
    List<DietPlanDay>? days,
    List<ShoppingListItem>? shoppingList,
    List<String>? followUpTips,
    String? mindfulBreakMessage,
    int? mindfulBreakHour,
    int? mindfulBreakMinute,
    SleepRoutineInfo? sleepRoutine,
    WellnessDigestInfo? wellnessDigest,
    MovementBreakInfo? movementRoutine,
    SunlightExposureInfo? sunlightRoutine,
  }) {
    return DietPlan(
      strategy: strategy ?? this.strategy,
      targets: targets ?? this.targets,
      hydrationGoal: hydrationGoal ?? this.hydrationGoal,
      hydrationPlan: hydrationPlan ?? this.hydrationPlan,
      highlights: highlights ?? this.highlights,
      days: days ?? this.days,
      shoppingList: shoppingList ?? this.shoppingList,
      followUpTips: followUpTips ?? this.followUpTips,
      mindfulBreakMessage:
          mindfulBreakMessage ?? this.mindfulBreakMessage,
      mindfulBreakHour: mindfulBreakHour ?? this.mindfulBreakHour,
      mindfulBreakMinute: mindfulBreakMinute ?? this.mindfulBreakMinute,
      sleepRoutine: sleepRoutine ?? this.sleepRoutine,
      wellnessDigest: wellnessDigest ?? this.wellnessDigest,
      movementRoutine: movementRoutine ?? this.movementRoutine,
      sunlightRoutine: sunlightRoutine ?? this.sunlightRoutine,
    );
  }

  factory DietPlan.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return DietPlan(
        strategy:
            'Planejamento não gerado. Gere um novo cardápio para receber recomendações personalizadas.',
        targets: const DietPlanTargets(
          caloriesPerDay: 1800,
          carbsPercentage: 45,
          proteinPercentage: 30,
          fatPercentage: 25,
        ),
        hydrationGoal: 'Beba ao menos 35 ml de água por quilo diariamente.',
        hydrationPlan: const HydrationPlanInfo(
          totalMl: 2000,
          tip: 'Distribua a hidratação ao longo do dia para manter energia e foco.',
          reminders: <HydrationReminderSlot>[],
        ),
        highlights: const <String>[],
        days: const <DietPlanDay>[],
        shoppingList: const <ShoppingListItem>[],
        followUpTips: const <String>[],
        mindfulBreakMessage:
            'Separe alguns minutos para alongar, respirar fundo e beber água à tarde.',
        mindfulBreakHour: 15,
        mindfulBreakMinute: 0,
        sleepRoutine: const SleepRoutineInfo(
          enabled: false,
          reminderHour: 22,
          reminderMinute: 0,
          message: '',
          windDownSummary: '',
          windDownTips: <String>[],
        ),
        wellnessDigest: const WellnessDigestInfo(
          enabled: false,
          summary: '',
          highlights: <String>[],
          callToAction: '',
          hoursBeforeCheckIn: 12,
        ),
        movementRoutine: const MovementBreakInfo(
          enabled: false,
          summary: '',
          slots: <MovementBreakSlot>[],
          tips: <String>[],
        ),
        sunlightRoutine: const SunlightExposureInfo(
          enabled: false,
          reminderHour: 9,
          reminderMinute: 0,
          durationMinutes: 15,
          message: '',
          benefits: <String>[],
          cautions: <String>[],
        ),
      );
    }

    final rawDays = map['days'];
    final days = rawDays is Iterable
        ? rawDays
            .map((dynamic item) =>
                DietPlanDay.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <DietPlanDay>[];

    final rawShopping = map['shoppingList'];
    final shopping = rawShopping is Iterable
        ? rawShopping
            .map((dynamic item) =>
                ShoppingListItem.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <ShoppingListItem>[];

    return DietPlan(
      strategy: _readString(map['strategy']) ??
          'Personalize suas refeições para equilibrar macronutrientes e variedade.',
      targets: DietPlanTargets.fromMap(map['targets'] as Map<String, dynamic>?),
      hydrationGoal:
          _readString(map['hydrationGoal']) ?? 'Beba ao menos 2 litros de água por dia.',
      hydrationPlan:
          HydrationPlanInfo.fromMap(map['hydrationPlan'] as Map<String, dynamic>?),
      highlights: _readStringList(map['highlights']),
      days: List<DietPlanDay>.unmodifiable(days),
      shoppingList: List<ShoppingListItem>.unmodifiable(shopping),
      followUpTips: _readStringList(map['followUpTips']),
      mindfulBreakMessage: _readString(map['mindfulBreakMessage']) ??
          'Reserve uma pausa rápida para alongar o corpo e aliviar a mente.',
      mindfulBreakHour: (map['mindfulBreakHour'] as num?)?.toInt().clamp(0, 23) ??
          15,
      mindfulBreakMinute:
          (map['mindfulBreakMinute'] as num?)?.toInt().clamp(0, 59) ?? 0,
      sleepRoutine:
          SleepRoutineInfo.fromMap(map['sleepRoutine'] as Map<String, dynamic>?),
      wellnessDigest:
          WellnessDigestInfo.fromMap(map['wellnessDigest'] as Map<String, dynamic>?),
      movementRoutine:
          MovementBreakInfo.fromMap(map['movementRoutine'] as Map<String, dynamic>?),
      sunlightRoutine:
          SunlightExposureInfo.fromMap(map['sunlightRoutine'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'strategy': strategy,
      'targets': targets.toMap(),
      'hydrationGoal': hydrationGoal,
      'hydrationPlan': hydrationPlan.toMap(),
      'highlights': highlights,
      'days': days.map((day) => day.toMap()).toList(),
      'shoppingList': shoppingList.map((item) => item.toMap()).toList(),
      'followUpTips': followUpTips,
      'mindfulBreakMessage': mindfulBreakMessage,
      'mindfulBreakHour': mindfulBreakHour,
      'mindfulBreakMinute': mindfulBreakMinute,
      'sleepRoutine': sleepRoutine.toMap(),
      'wellnessDigest': wellnessDigest.toMap(),
      'movementRoutine': movementRoutine.toMap(),
      'sunlightRoutine': sunlightRoutine.toMap(),
    };
  }
}

@immutable
class WeightEntry {
  const WeightEntry({
    required this.date,
    required this.weightKg,
  });

  final DateTime date;
  final double weightKg;

  factory WeightEntry.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return WeightEntry(
        date: DateTime.now(),
        weightKg: 0,
      );
    }

    DateTime _readDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      try {
        final dynamic candidate = value;
        final result = candidate?.toDate();
        if (result is DateTime) {
          return result;
        }
      } catch (_) {
        // Ignored: not a Timestamp-like object.
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is Map<String, dynamic>) {
        int? _readInt(dynamic input) {
          if (input is int) {
            return input;
          }
          if (input is num) {
            return input.toInt();
          }
          if (input is String) {
            return int.tryParse(input);
          }
          return null;
        }

        final seconds = _readInt(value['seconds']);
        final nanoseconds = _readInt(value['nanoseconds']) ?? 0;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        }
      }
      return DateTime.now();
    }

    double _readDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }
      return 0;
    }

    return WeightEntry(
      date: _readDate(map['date']),
      weightKg: _readDouble(map['weightKg']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date,
      'weightKg': weightKg,
    };
  }
}

@immutable
class MealLogEntry {
  const MealLogEntry({
    required this.consumed,
    required this.portionFactor,
    this.note,
    required this.updatedAt,
  });

  final bool consumed;
  final double portionFactor;
  final String? note;
  final DateTime updatedAt;

  MealLogEntry copyWith({
    bool? consumed,
    double? portionFactor,
    String? note,
    DateTime? updatedAt,
  }) {
    return MealLogEntry(
      consumed: consumed ?? this.consumed,
      portionFactor: portionFactor ?? this.portionFactor,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MealLogEntry.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return MealLogEntry(
        consumed: false,
        portionFactor: 0,
        note: null,
        updatedAt: DateTime.now(),
      );
    }

    DateTime _readDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      try {
        final dynamic candidate = value;
        final result = candidate?.toDate();
        if (result is DateTime) {
          return result;
        }
      } catch (_) {
        // ignored
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is Map<String, dynamic>) {
        final seconds = (value['seconds'] as num?)?.toInt();
        final nanos = (value['nanoseconds'] as num?)?.toInt() ?? 0;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanos ~/ 1000000),
          );
        }
      }
      return DateTime.now();
    }

    double _readPortion(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }
      return 0;
    }

    return MealLogEntry(
      consumed: map['consumed'] as bool? ?? false,
      portionFactor: _readPortion(map['portionFactor']).clamp(0.0, 1.5),
      note: _readString(map['note']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'consumed': consumed,
      'portionFactor': portionFactor,
      'note': note,
      'updatedAt': updatedAt,
    };
  }
}

@immutable
class NutritionPlan {
  NutritionPlan({
    required this.profile,
    required this.plan,
    required this.generatedAt,
    required this.nextCheckInAt,
    required this.lastWeighInKg,
    required this.weightHistory,
    required this.needsAdjustment,
    required Set<String> completedMeals,
    Map<String, MealLogEntry>? mealLogs,
  })  : completedMeals = Set<String>.unmodifiable(completedMeals),
        mealLogs = Map<String, MealLogEntry>.unmodifiable(
          mealLogs ?? const <String, MealLogEntry>{},
        );

  final DietProfile profile;
  final DietPlan plan;
  final DateTime generatedAt;
  final DateTime nextCheckInAt;
  final double lastWeighInKg;
  final List<WeightEntry> weightHistory;
  final bool needsAdjustment;
  final Set<String> completedMeals;
  final Map<String, MealLogEntry> mealLogs;

  double get startingWeightKg =>
      weightHistory.isNotEmpty ? weightHistory.first.weightKg : lastWeighInKg;

  bool get isCheckInOverdue => DateTime.now().isAfter(nextCheckInAt);

  NutritionPlan copyWith({
    DietProfile? profile,
    DietPlan? plan,
    DateTime? generatedAt,
    DateTime? nextCheckInAt,
    double? lastWeighInKg,
    List<WeightEntry>? weightHistory,
    bool? needsAdjustment,
    Set<String>? completedMeals,
    Map<String, MealLogEntry>? mealLogs,
  }) {
    return NutritionPlan(
      profile: profile ?? this.profile,
      plan: plan ?? this.plan,
      generatedAt: generatedAt ?? this.generatedAt,
      nextCheckInAt: nextCheckInAt ?? this.nextCheckInAt,
      lastWeighInKg: lastWeighInKg ?? this.lastWeighInKg,
      weightHistory: weightHistory ?? this.weightHistory,
      needsAdjustment: needsAdjustment ?? this.needsAdjustment,
      completedMeals:
          completedMeals != null ? Set<String>.unmodifiable(completedMeals) : this.completedMeals,
      mealLogs: mealLogs ?? this.mealLogs,
    );
  }

  factory NutritionPlan.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('Plano de nutrição inválido.');
    }

    DateTime _readDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      try {
        final dynamic candidate = value;
        final result = candidate?.toDate();
        if (result is DateTime) {
          return result;
        }
      } catch (_) {
        // Ignored.
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is Map<String, dynamic>) {
        int? _readInt(dynamic input) {
          if (input is int) {
            return input;
          }
          if (input is num) {
            return input.toInt();
          }
          if (input is String) {
            return int.tryParse(input);
          }
          return null;
        }

        final seconds = _readInt(value['seconds']);
        final nanoseconds = _readInt(value['nanoseconds']) ?? 0;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        }
      }
      return DateTime.now();
    }

    final rawHistory = map['weightHistory'];
    final history = rawHistory is Iterable
        ? rawHistory
            .map((dynamic item) => WeightEntry.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <WeightEntry>[];

    final completedMeals = Set<String>.from(_readStringList(map['completedMeals']));
    final logs = <String, MealLogEntry>{};
    final rawLogs = map['mealLogs'];
    if (rawLogs is Map<String, dynamic>) {
      rawLogs.forEach((key, dynamic value) {
        if (value is Map<String, dynamic>) {
          logs[key] = MealLogEntry.fromMap(value);
        }
      });
    }

    return NutritionPlan(
      profile: DietProfile.fromMap(map['profile'] as Map<String, dynamic>?),
      plan: DietPlan.fromMap(map['plan'] as Map<String, dynamic>?),
      generatedAt: _readDate(map['generatedAt']),
      nextCheckInAt: _readDate(map['nextCheckInAt']),
      lastWeighInKg: (map['lastWeighInKg'] as num?)?.toDouble() ?? 0,
      weightHistory: List<WeightEntry>.unmodifiable(history),
      needsAdjustment: map['needsAdjustment'] as bool? ?? false,
      completedMeals: completedMeals,
      mealLogs: logs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'profile': profile.toMap(),
      'plan': plan.toMap(),
      'generatedAt': generatedAt,
      'nextCheckInAt': nextCheckInAt,
      'lastWeighInKg': lastWeighInKg,
      'weightHistory': weightHistory.map((entry) => entry.toMap()).toList(),
      'needsAdjustment': needsAdjustment,
      'completedMeals': completedMeals.toList(),
      'mealLogs': mealLogs.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  static String mealKey(int dayIndex, int mealIndex) => 'd$dayIndex-m$mealIndex';

  MealLogEntry? mealLog(int dayIndex, int mealIndex) {
    return mealLogs[mealKey(dayIndex, mealIndex)];
  }

  double _portionFactor(int dayIndex, int mealIndex, {double maxFactor = 1.5}) {
    final key = mealKey(dayIndex, mealIndex);
    final log = mealLogs[key];
    if (log != null) {
      final clamped = log.portionFactor.clamp(0.0, maxFactor);
      return clamped is num ? clamped.toDouble() : maxFactor;
    }
    return completedMeals.contains(key) ? 1.0 : 0.0;
  }

  bool isMealCompleted(int dayIndex, int mealIndex) {
    final key = mealKey(dayIndex, mealIndex);
    if (mealLogs.containsKey(key)) {
      return mealLogs[key]!.consumed;
    }
    return completedMeals.contains(key);
  }

  NutritionPlan updateMealCompletion({
    required int dayIndex,
    required int mealIndex,
    required bool completed,
  }) {
    final updated = Set<String>.from(completedMeals);
    final key = mealKey(dayIndex, mealIndex);
    if (completed) {
      updated.add(key);
    } else {
      updated.remove(key);
    }
    final updatedLogs = Map<String, MealLogEntry>.from(mealLogs);
    updatedLogs[key] = (updatedLogs[key] ??
            MealLogEntry(
              consumed: completed,
              portionFactor: completed ? 1 : 0,
              note: null,
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      consumed: completed,
      portionFactor: completed ? 1 : 0,
      updatedAt: DateTime.now(),
    );
    if (!completed) {
      updatedLogs[key] = updatedLogs[key]!.copyWith(portionFactor: 0, note: null);
    }
    return copyWith(completedMeals: updated, mealLogs: updatedLogs);
  }

  NutritionPlan updateMealLog({
    required int dayIndex,
    required int mealIndex,
    required double portionFactor,
    String? note,
  }) {
    final key = mealKey(dayIndex, mealIndex);
    final clampedPortion = portionFactor.clamp(0.0, 1.5);
    final consumed = clampedPortion >= 0.5;
    final updatedCompleted = Set<String>.from(completedMeals);
    if (consumed) {
      updatedCompleted.add(key);
    } else {
      updatedCompleted.remove(key);
    }
    final cleanedNote = note?.trim();
    final previousNote = mealLogs[key]?.note;
    final effectiveNote =
        cleanedNote == null || cleanedNote.isEmpty ? previousNote : cleanedNote;
    final updatedLogs = Map<String, MealLogEntry>.from(mealLogs)
      ..[key] = MealLogEntry(
        consumed: consumed,
        portionFactor: clampedPortion,
        note: clampedPortion <= 0.05 ? null : effectiveNote,
        updatedAt: DateTime.now(),
      );
    return copyWith(completedMeals: updatedCompleted, mealLogs: updatedLogs);
  }

  int totalMealsForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      return 0;
    }
    return plan.days[dayIndex].meals.length;
  }

  int completedMealsForDay(int dayIndex) {
    final total = totalMealsForDay(dayIndex);
    if (total == 0) {
      return 0;
    }
    var count = 0;
    for (var i = 0; i < total; i++) {
      final log = mealLog(dayIndex, i);
      if (log != null) {
        if (log.consumed && log.portionFactor >= 0.5) {
          count++;
        }
        continue;
      }
      if (isMealCompleted(dayIndex, i)) {
        count++;
      }
    }
    return count;
  }

  double dayCompletionRatio(int dayIndex) {
    final total = totalMealsForDay(dayIndex);
    if (total == 0) {
      return 0;
    }
    var sum = 0.0;
    for (var i = 0; i < total; i++) {
      sum += _portionFactor(dayIndex, i, maxFactor: 1.0);
    }
    return total == 0 ? 0 : sum / total;
  }

  double overallCompletionRatio() {
    if (plan.days.isEmpty) {
      return 0;
    }
    var totalMeals = 0;
    var totalPortion = 0.0;
    for (var dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final meals = plan.days[dayIndex].meals.length;
      totalMeals += meals;
      for (var mealIndex = 0; mealIndex < meals; mealIndex++) {
        totalPortion += _portionFactor(dayIndex, mealIndex, maxFactor: 1.0);
      }
    }
    if (totalMeals == 0) {
      return 0;
    }
    return totalPortion / totalMeals;
  }

  double targetCaloriesForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      return plan.targets.caloriesPerDay.toDouble();
    }
    final day = plan.days[dayIndex];
    final fallback = plan.targets.caloriesPerDay;
    final total = day.totalCalories;
    return (total ?? fallback).toDouble();
  }

  double consumedCaloriesForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      return 0;
    }
    final day = plan.days[dayIndex];
    final totalMeals = day.meals.length;
    if (totalMeals == 0) {
      return 0;
    }
    final target = targetCaloriesForDay(dayIndex);
    final fallbackPerMeal = totalMeals == 0 ? 0 : target / totalMeals;
    var total = 0.0;
    for (var i = 0; i < totalMeals; i++) {
      final meal = day.meals[i];
      final baseCalories = (meal.calories != null && meal.calories! > 0)
          ? meal.calories!.toDouble()
          : fallbackPerMeal;
      final portion = _portionFactor(dayIndex, i, maxFactor: 1.2);
      total += baseCalories * portion;
    }
    return double.parse(total.toStringAsFixed(0));
  }

  Map<String, double> consumedMacroGramsForDay(int dayIndex) {
    final ratio = dayCompletionRatio(dayIndex).clamp(0.0, 1.0);
    final macros = plan.targets.macroGrams();
    final result = <String, double>{};
    macros.forEach((key, value) {
      result[key] = double.parse((value * ratio).toStringAsFixed(1));
    });
    return result;
  }

  bool dayHasProgress(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= plan.days.length) {
      return false;
    }
    final total = totalMealsForDay(dayIndex);
    if (total == 0) {
      return false;
    }
    for (var i = 0; i < total; i++) {
      final key = mealKey(dayIndex, i);
      if (completedMeals.contains(key)) {
        return true;
      }
      final log = mealLogs[key];
      if (log != null) {
        if (log.portionFactor > 0.01) {
          return true;
        }
        if ((log.note ?? '').trim().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  int pendingMealsForDay(int dayIndex) {
    final total = totalMealsForDay(dayIndex);
    if (total == 0) {
      return 0;
    }
    final completed = completedMealsForDay(dayIndex);
    return math.max(0, total - completed);
  }

  int currentDayIndex({DateTime? reference}) {
    if (plan.days.isEmpty) {
      return 0;
    }
    final base = DateTime(generatedAt.year, generatedAt.month, generatedAt.day);
    final now = reference ?? DateTime.now();
    final diffDays = now.difference(base).inDays;
    if (diffDays <= 0) {
      return 0;
    }
    final maxIndex = plan.days.length - 1;
    final clamped = diffDays.clamp(0, maxIndex);
    return clamped is num ? clamped.toInt() : 0;
  }

  int adherenceStreak({double threshold = 0.75, DateTime? reference}) {
    if (plan.days.isEmpty) {
      return 0;
    }
    final startIndex = currentDayIndex(reference: reference);
    var streak = 0;
    for (var dayIndex = startIndex; dayIndex >= 0; dayIndex--) {
      if (!dayHasProgress(dayIndex)) {
        break;
      }
      final ratio = dayCompletionRatio(dayIndex);
      if (ratio >= threshold) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

String? _readString(dynamic value) {
  if (value is String) {
    final sanitized = value.trim();
    return sanitized.isEmpty ? null : sanitized;
  }
  return null;
}

List<String> _readOrderedList(dynamic value) {
  if (value is Iterable) {
    final list = value
        .map((dynamic item) => item?.toString())
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return List<String>.unmodifiable(list);
  }
  return const <String>[];
}

List<String> _readStringList(dynamic value) {
  if (value is Iterable) {
    final list = value
        .map((dynamic item) => item?.toString())
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(list);
  }
  return const <String>[];
}
