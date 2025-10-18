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
class DietPlanMeal {
  const DietPlanMeal({
    required this.name,
    required this.description,
    this.calories,
    this.macroFocus,
    this.prepNotes,
  });

  final String name;
  final String description;
  final int? calories;
  final String? macroFocus;
  final String? prepNotes;

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
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'calories': calories,
      'macroFocus': macroFocus,
      'prepNotes': prepNotes,
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
  });

  final String category;
  final String item;
  final String quantity;
  final String? notes;

  factory ShoppingListItem.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ShoppingListItem(
        category: 'Diversos',
        item: 'Ingrediente não especificado',
        quantity: '1 unidade',
      );
    }

    return ShoppingListItem(
      category: _readString(map['category']) ?? 'Diversos',
      item: _readString(map['item']) ?? 'Ingrediente não especificado',
      quantity: _readString(map['quantity']) ?? '1 unidade',
      notes: _readString(map['notes']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'category': category,
      'item': item,
      'quantity': quantity,
      'notes': notes,
    };
  }
}

@immutable
class DietPlan {
  const DietPlan({
    required this.strategy,
    required this.targets,
    required this.hydrationGoal,
    required this.highlights,
    required this.days,
    required this.shoppingList,
    required this.followUpTips,
  });

  final String strategy;
  final DietPlanTargets targets;
  final String hydrationGoal;
  final List<String> highlights;
  final List<DietPlanDay> days;
  final List<ShoppingListItem> shoppingList;
  final List<String> followUpTips;

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
        highlights: const <String>[],
        days: const <DietPlanDay>[],
        shoppingList: const <ShoppingListItem>[],
        followUpTips: const <String>[],
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
      highlights: _readStringList(map['highlights']),
      days: List<DietPlanDay>.unmodifiable(days),
      shoppingList: List<ShoppingListItem>.unmodifiable(shopping),
      followUpTips: _readStringList(map['followUpTips']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'strategy': strategy,
      'targets': targets.toMap(),
      'hydrationGoal': hydrationGoal,
      'highlights': highlights,
      'days': days.map((day) => day.toMap()).toList(),
      'shoppingList': shoppingList.map((item) => item.toMap()).toList(),
      'followUpTips': followUpTips,
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
class NutritionPlan {
  const NutritionPlan({
    required this.profile,
    required this.plan,
    required this.generatedAt,
    required this.nextCheckInAt,
    required this.lastWeighInKg,
    required this.weightHistory,
    required this.needsAdjustment,
  });

  final DietProfile profile;
  final DietPlan plan;
  final DateTime generatedAt;
  final DateTime nextCheckInAt;
  final double lastWeighInKg;
  final List<WeightEntry> weightHistory;
  final bool needsAdjustment;

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
  }) {
    return NutritionPlan(
      profile: profile ?? this.profile,
      plan: plan ?? this.plan,
      generatedAt: generatedAt ?? this.generatedAt,
      nextCheckInAt: nextCheckInAt ?? this.nextCheckInAt,
      lastWeighInKg: lastWeighInKg ?? this.lastWeighInKg,
      weightHistory: weightHistory ?? this.weightHistory,
      needsAdjustment: needsAdjustment ?? this.needsAdjustment,
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

    return NutritionPlan(
      profile: DietProfile.fromMap(map['profile'] as Map<String, dynamic>?),
      plan: DietPlan.fromMap(map['plan'] as Map<String, dynamic>?),
      generatedAt: _readDate(map['generatedAt']),
      nextCheckInAt: _readDate(map['nextCheckInAt']),
      lastWeighInKg: (map['lastWeighInKg'] as num?)?.toDouble() ?? 0,
      weightHistory: List<WeightEntry>.unmodifiable(history),
      needsAdjustment: map['needsAdjustment'] as bool? ?? false,
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
    };
  }
}

String? _readString(dynamic value) {
  if (value is String) {
    final sanitized = value.trim();
    return sanitized.isEmpty ? null : sanitized;
  }
  return null;
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
