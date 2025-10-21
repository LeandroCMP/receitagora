import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';
import 'package:receitagora/services/openai/openai_service.dart';
import 'package:receitagora/services/session/session_service.dart';

enum RegenerationTrigger { initial, variety, progress, adjustment }

class NutritionPlanRegenerationResult {
  const NutritionPlanRegenerationResult({
    required this.plan,
    required this.trigger,
  });

  final NutritionPlan plan;
  final RegenerationTrigger trigger;
}

class NutritionPlanService extends GetxService {
  NutritionPlanService({
    required this.firestore,
    required this.openAIService,
    required this.sessionService,
  });

  final FirebaseFirestore firestore;
  final OpenAIService openAIService;
  final SessionService sessionService;

  DocumentReference<Map<String, dynamic>>? _planDocument() {
    final userId = sessionService.user?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('plan');
  }

  Stream<NutritionPlan?> watchCurrentPlan() async* {
    await sessionService.ensureInitialized();
    final doc = _planDocument();
    if (doc == null) {
      yield* const Stream<NutritionPlan?>.empty();
      return;
    }
    yield* doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return NutritionPlan.fromMap(data);
    });
  }

  Future<NutritionPlan?> fetchCurrentPlan() async {
    await sessionService.ensureInitialized();
    final doc = _planDocument();
    if (doc == null) {
      return null;
    }
    final snapshot = await doc.get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return NutritionPlan.fromMap(data);
  }

  Future<NutritionPlan> generatePlan(DietProfile profile) async {
    await sessionService.ensureInitialized();
    if (!sessionService.hasPremiumAccess) {
      throw const AppException(
        'O plano nutricional é exclusivo para assinantes Premium. Faça o upgrade para acessar o cardápio personalizado.',
      );
    }

    final doc = _planDocument();
    if (doc == null) {
      throw const AppException('É necessário estar autenticado para gerar o plano.');
    }

    final systemPrompt =
        'Você é o Chef Nutricional do Receitagora. Crie cardápios brasileiros equilibrados, com foco em segurança, variedade e viabilidade para o dia a dia.';
    final recommendedTargets = _calculateRecommendedTargets(profile);
    final userPrompt = _buildPlanPrompt(
      profile,
      recommendedTargets: recommendedTargets,
      trigger: RegenerationTrigger.initial,
    );
    final response = await openAIService.requestStructuredJson(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.55,
    );

    final plan =
        _normalizePlan(DietPlan.fromMap(response), profile, recommendedTargets);
    final now = DateTime.now();
    final nextCheckIn = now.add(profile.interval.duration);
    final initialHistory = <WeightEntry>[
      WeightEntry(date: now, weightKg: profile.weightKg),
    ];
    final nutritionPlan = NutritionPlan(
      profile: profile,
      plan: plan,
      generatedAt: now,
      nextCheckInAt: nextCheckIn,
      lastWeighInKg: profile.weightKg,
      weightHistory: List<WeightEntry>.unmodifiable(initialHistory),
      needsAdjustment: false,
      completedMeals: const <String>{},
      mealLogs: const <String, MealLogEntry>{},
    );

    await doc.set(_serializePlan(nutritionPlan));
    return nutritionPlan;
  }

  Future<NutritionPlan> regeneratePlan({
    NutritionPlan? planOverride,
    RegenerationTrigger trigger = RegenerationTrigger.variety,
  }) async {
    await sessionService.ensureInitialized();
    if (!sessionService.hasPremiumAccess) {
      throw const AppException(
        'O plano nutricional é exclusivo para assinantes Premium. Faça o upgrade para acessar o cardápio personalizado.',
      );
    }

    final doc = _planDocument();
    if (doc == null) {
      throw const AppException('É necessário estar autenticado para gerar o plano.');
    }

    final current = planOverride ?? await fetchCurrentPlan();
    if (current == null) {
      throw const AppException('Gere um cardápio inicial antes de solicitar uma nova variação.');
    }

    final systemPrompt =
        'Você é o Chef Nutricional do Receitagora. Crie cardápios brasileiros equilibrados, com foco em segurança, variedade e viabilidade para o dia a dia.';
    final recommendedTargets =
        _calculateRecommendedTargets(current.profile, previousPlan: current);
    final userPrompt = _buildPlanPrompt(
      current.profile,
      recommendedTargets: recommendedTargets,
      previousPlan: current,
      trigger: trigger,
    );
    final response = await openAIService.requestStructuredJson(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.65,
    );

    final plan = _normalizePlan(
      DietPlan.fromMap(response),
      current.profile,
      recommendedTargets,
    );
    final now = DateTime.now();
    final updatedPlan = current.copyWith(
      plan: plan,
      generatedAt: now,
      nextCheckInAt: now.add(current.profile.interval.duration),
      needsAdjustment: false,
      completedMeals: const <String>{},
      mealLogs: const <String, MealLogEntry>{},
    );

    await doc.set(_serializePlan(updatedPlan), SetOptions(merge: true));
    return updatedPlan;
  }

  Future<NutritionPlan> setMealCompletion({
    required NutritionPlan plan,
    required int dayIndex,
    required int mealIndex,
    required bool completed,
  }) async {
    await sessionService.ensureInitialized();
    final doc = _planDocument();
    if (doc == null) {
      throw const AppException('É necessário estar autenticado para atualizar o progresso do cardápio.');
    }

    final updated = plan.updateMealCompletion(
      dayIndex: dayIndex,
      mealIndex: mealIndex,
      completed: completed,
    );

    await doc.set(
      <String, dynamic>{
        'completedMeals': updated.completedMeals.toList(),
        'mealLogs': updated.mealLogs.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      },
      SetOptions(merge: true),
    );

    return updated;
  }

  Future<NutritionPlan> recordMealLog({
    required NutritionPlan plan,
    required int dayIndex,
    required int mealIndex,
    required double portionFactor,
    String? notes,
  }) async {
    await sessionService.ensureInitialized();
    final doc = _planDocument();
    if (doc == null) {
      throw const AppException('É necessário estar autenticado para atualizar o diário alimentar.');
    }

    final updated = plan.updateMealLog(
      dayIndex: dayIndex,
      mealIndex: mealIndex,
      portionFactor: portionFactor,
      note: notes,
    );

    await doc.set(
      <String, dynamic>{
        'completedMeals': updated.completedMeals.toList(),
        'mealLogs': updated.mealLogs.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      },
      SetOptions(merge: true),
    );

    return updated;
  }

  Future<NutritionPlanRegenerationResult> recordWeighIn(double weightKg) async {
    if (weightKg <= 0) {
      throw const AppException('Informe um peso válido para registrar o check-in.');
    }
    final current = await fetchCurrentPlan();
    if (current == null) {
      throw const AppException('Nenhum plano encontrado. Gere um cardápio antes de registrar o peso.');
    }

    if (!current.isCheckInOverdue) {
      throw const AppException('Aguarde o término do ciclo atual para registrar o peso.');
    }

    final now = DateTime.now();
    final history = List<WeightEntry>.from(current.weightHistory)
      ..add(WeightEntry(date: now, weightKg: weightKg));

    final updatedProfile = current.profile.copyWith(weightKg: weightKg);
    final needsAdjustment = _shouldAdjustStrategy(
      goal: current.profile.goal,
      previousWeight: current.lastWeighInKg,
      currentWeight: weightKg,
      history: history,
      interval: current.profile.interval,
    );

    final updatedPlan = current.copyWith(
      profile: updatedProfile,
      lastWeighInKg: weightKg,
      weightHistory: List<WeightEntry>.unmodifiable(history),
      needsAdjustment: needsAdjustment,
    );

    final trigger =
        needsAdjustment ? RegenerationTrigger.adjustment : RegenerationTrigger.progress;
    final plan = await regeneratePlan(
      planOverride: updatedPlan,
      trigger: trigger,
    );

    return NutritionPlanRegenerationResult(plan: plan, trigger: trigger);
  }

  Map<String, dynamic> _serializePlan(NutritionPlan plan) {
    return <String, dynamic>{
      'profile': plan.profile.toMap(),
      'plan': plan.plan.toMap(),
      'generatedAt': Timestamp.fromDate(plan.generatedAt),
      'nextCheckInAt': Timestamp.fromDate(plan.nextCheckInAt),
      'lastWeighInKg': plan.lastWeighInKg,
      'needsAdjustment': plan.needsAdjustment,
      'completedMeals': plan.completedMeals.toList(),
      'weightHistory': plan.weightHistory
          .map((entry) => <String, dynamic>{
                'date': Timestamp.fromDate(entry.date),
                'weightKg': entry.weightKg,
              })
          .toList(),
      'mealLogs': plan.mealLogs.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  bool _shouldAdjustStrategy({
    required DietGoal goal,
    required double previousWeight,
    required double currentWeight,
    required List<WeightEntry> history,
    required DietPlanInterval interval,
  }) {
    if (history.length < 2) {
      final delta = (currentWeight - previousWeight).abs();
      switch (goal) {
        case DietGoal.loseWeight:
        case DietGoal.gainMass:
          return delta < 0.2;
        case DietGoal.maintain:
          return delta > 0.5;
        case DietGoal.reeducate:
          return delta > 0.6;
      }
    }

    final avgWeekly = _calculateWeeklyTrend(history);
    final delta = currentWeight - previousWeight;
    final cycleWeeks = interval.duration.inDays / 7;
    final toleranceAdjustment = cycleWeeks > 2 ? 0.05 : 0.0;
    switch (goal) {
      case DietGoal.loseWeight:
        if (delta > 0.2) {
          return true;
        }
        return avgWeekly > (-0.2 + toleranceAdjustment);
      case DietGoal.gainMass:
        if (delta < -0.2) {
          return true;
        }
        return avgWeekly < (0.2 - toleranceAdjustment);
      case DietGoal.maintain:
        return avgWeekly.abs() > (0.25 + toleranceAdjustment);
      case DietGoal.reeducate:
        return avgWeekly.abs() > (0.35 + toleranceAdjustment);
    }
  }

  String _buildPlanPrompt(
    DietProfile profile, {
    required DietPlanTargets recommendedTargets,
    NutritionPlan? previousPlan,
    required RegenerationTrigger trigger,
  }) {
    final user = sessionService.user;
    final buffer = StringBuffer();
    buffer.writeln('Monte um plano ${profile.interval.label.toLowerCase()} com foco em ${profile.goal.label.toLowerCase()}.');
    buffer.writeln('Dados biométricos: altura ${profile.heightCm.toStringAsFixed(1)} cm, peso ${profile.weightKg.toStringAsFixed(1)} kg, IMC ${profile.bmi}.');
    buffer.writeln('Nível de atividade: ${profile.activityLevel.label}.');
    buffer.writeln(
        'Autoavaliação do metabolismo: ${profile.metabolicProfileLabel} (nível ${profile.metabolicEase} de 5).');
    buffer.writeln('Estilo de preparo preferido: ${profile.cookingStyle.label}.');
    final expectedDays =
        profile.interval == DietPlanInterval.weekly ? 7 : 30;
    buffer.writeln('Planejamento ${expectedDays == 7 ? 'de 7 dias' : 'de 30 dias'} com refeições brasileiras modernas.');
    final macros = recommendedTargets.macroGrams();
    buffer.writeln(
        'Metas energéticas recomendadas: ${recommendedTargets.caloriesPerDay} kcal/dia com distribuição de ${recommendedTargets.carbsPercentage.toStringAsFixed(0)}% carboidratos (~${macros['carbs']} g), ${recommendedTargets.proteinPercentage.toStringAsFixed(0)}% proteínas (~${macros['proteins']} g) e ${recommendedTargets.fatPercentage.toStringAsFixed(0)}% gorduras (~${macros['fats']} g).');
    buffer.writeln(
        'Garanta que a soma das refeições de cada dia fique entre ${recommendedTargets.caloriesPerDay - 150} e ${recommendedTargets.caloriesPerDay + 150} kcal.');
    buffer.writeln('Frequência de lanches: ${profile.snackFrequency}.');
    buffer.writeln('Preferência por ingredientes brasileiros? ${profile.prefersBrazilianCuisine ? 'Sim' : 'Aberto a sabores internacionais'}.');
    buffer.writeln('Usar produtos sazonais? ${profile.prefersSeasonalProduce ? 'Priorizar ingredientes da estação' : 'Sem restrição sazonal'}.');
    if (profile.additionalNotes != null && profile.additionalNotes!.trim().isNotEmpty) {
      buffer.writeln('Observações adicionais do usuário: ${profile.additionalNotes}.');
    }
    if (user != null) {
      if (user.dietaryPreferences.isNotEmpty) {
        buffer.writeln('Preferências declaradas: ${user.dietaryPreferences.join(', ')}.');
      }
      if (user.allergies.isNotEmpty) {
        buffer.writeln('Evite ingredientes com risco de alergia: ${user.allergies.join(', ')}.');
      }
      if (user.favoriteCuisines.isNotEmpty) {
        buffer.writeln('Culinárias favoritas: ${user.favoriteCuisines.join(', ')}.');
      }
    }

    if (previousPlan != null) {
      final history = previousPlan.weightHistory
          .map((entry) => '${entry.date.toIso8601String().split('T').first}: ${entry.weightKg.toStringAsFixed(1)} kg')
          .join(' | ');
      buffer.writeln('Histórico de peso recente: $history.');
      switch (trigger) {
        case RegenerationTrigger.adjustment:
          buffer.writeln(
              'O ciclo anterior não trouxe o resultado desejado. Ajuste calorias, macronutrientes e estratégias (como hidratação, descanso e preparo em lote) para acelerar resultados sem comprometer a segurança.');
          break;
        case RegenerationTrigger.progress:
          buffer.writeln(
              'O ciclo anterior gerou bons resultados. Mantenha a estratégia principal, mas ofereça variedade, reforçando hábitos que deram certo.');
          break;
        case RegenerationTrigger.variety:
          buffer.writeln(
              'O usuário solicitou uma nova variação mantendo os objetivos atuais, explorando combinações diferentes das já apresentadas.');
          break;
        case RegenerationTrigger.initial:
          break;
      }
      buffer.writeln('Evite repetir as mesmas combinações da última semana e proponha novidades mantendo equilíbrio nutricional.');
    } else {
      buffer.writeln('Entregue um cardápio inédito baseado nesses dados.');
    }

    buffer.writeln('Entregue EXATAMENTE $expectedDays objetos no array "days" abaixo, cada um com as quatro refeições principais nomeadas (Café da manhã, Lanche da manhã, Almoço e Jantar).');
    buffer.writeln('Inclua calorias aproximadas, macro foco e passos claros para cada refeição.');
    buffer.writeln('Estruture o JSON exatamente como segue:');
    buffer.writeln('{');
    buffer.writeln('  "strategy": "string",');
    buffer.writeln('  "targets": { "caloriesPerDay": number, "carbs": number, "proteins": number, "fats": number },');
    buffer.writeln('  "hydrationGoal": "string",');
    buffer.writeln('  "highlights": ["string"...],');
    buffer.writeln('  "days": [');
    buffer.writeln('    {');
    buffer.writeln('      "label": "Dia 1",');
    buffer.writeln('      "focus": "string",');
    buffer.writeln('      "meals": [');
    buffer.writeln(
        '        {"name": "Café da manhã", "description": "string", "calories": number, "macroFocus": "string", "prepNotes": "string", "ingredients": ["string"...], "steps": ["string"...], "difficulty": "string", "duration": "string"},');
    buffer.writeln(
        '        {"name": "Lanche da manhã", "description": "string", "calories": number, "macroFocus": "string", "prepNotes": "string", "ingredients": ["string"...], "steps": ["string"...], "difficulty": "string", "duration": "string"},');
    buffer.writeln(
        '        {"name": "Almoço", "description": "string", "calories": number, "macroFocus": "string", "prepNotes": "string", "ingredients": ["string"...], "steps": ["string"...], "difficulty": "string", "duration": "string"},');
    buffer.writeln(
        '        {"name": "Jantar", "description": "string", "calories": number, "macroFocus": "string", "prepNotes": "string", "ingredients": ["string"...], "steps": ["string"...], "difficulty": "string", "duration": "string"}');
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln('  "shoppingList": [');
    buffer.writeln('    {"category": "string", "item": "string", "quantity": "string", "notes": "string"}');
    buffer.writeln('  ],');
    buffer.writeln('  "followUpTips": ["string"...]');
    buffer.writeln('}');
    buffer.writeln('Utilize alimentos acessíveis no Brasil, com combinações sazonais quando aplicável e versões possíveis de congelar quando o usuário optar por produzir em lote.');
    buffer.writeln('Garanta que cada dia contenha exatamente as quatro refeições principais com os nomes informados acima e inclua lanches extras somente se estiverem no mesmo formato JSON.');
    buffer.writeln('Inclua variações coerentes com o objetivo ${profile.goal.promptKeyword} e utilize ingredientes acessíveis no Brasil.');
    buffer.writeln('Para cada refeição forneça ingredientes detalhados e um modo de preparo passo a passo claro, com duração média e nível de dificuldade compatíveis com o perfil informado.');

    return buffer.toString();
  }

  DietPlanTargets _calculateRecommendedTargets(
    DietProfile profile, {
    NutritionPlan? previousPlan,
  }) {
    final weight = profile.weightKg;
    final height = profile.heightCm;
    if (weight <= 0 || height <= 0) {
      return const DietPlanTargets(
        caloriesPerDay: 1800,
        carbsPercentage: 45,
        proteinPercentage: 30,
        fatPercentage: 25,
      );
    }

    const assumedAge = 30;
    final activityMultiplier = <DietActivityLevel, double>{
      DietActivityLevel.sedentary: 1.2,
      DietActivityLevel.light: 1.375,
      DietActivityLevel.moderate: 1.55,
      DietActivityLevel.intense: 1.725,
    }[profile.activityLevel]!;

    final metabolismFactor = 0.9 +
        (profile.metabolicEase.clamp(0, 5) * 0.04); // 0 -> 0.90, 5 -> 1.10

    final bmr = 10 * weight + 6.25 * height - 5 * assumedAge + 5;
    var calories = bmr * activityMultiplier * metabolismFactor;

    double goalAdjustment;
    double carbs;
    double proteins;
    double fats;

    switch (profile.goal) {
      case DietGoal.loseWeight:
        goalAdjustment = -0.18;
        carbs = 40;
        proteins = 35;
        fats = 25;
        break;
      case DietGoal.gainMass:
        goalAdjustment = 0.15;
        carbs = 50;
        proteins = 30;
        fats = 20;
        break;
      case DietGoal.maintain:
        goalAdjustment = 0.0;
        carbs = 45;
        proteins = 30;
        fats = 25;
        break;
      case DietGoal.reeducate:
        goalAdjustment = -0.08;
        carbs = 42;
        proteins = 33;
        fats = 25;
        break;
    }

    calories *= (1 + goalAdjustment);

    if (previousPlan != null) {
      final trend = _calculateWeeklyTrend(previousPlan.weightHistory);
      switch (profile.goal) {
        case DietGoal.loseWeight:
          if (trend > -0.15) {
            calories -= 120;
          } else if (trend < -0.8) {
            calories += 80;
          }
          break;
        case DietGoal.gainMass:
          if (trend < 0.15) {
            calories += 120;
          } else if (trend > 0.6) {
            calories -= 80;
          }
          break;
        case DietGoal.maintain:
          if (trend.abs() > 0.3) {
            calories += trend > 0 ? -120 : 120;
          }
          break;
        case DietGoal.reeducate:
          if (trend.abs() > 0.4) {
            calories += trend > 0 ? -100 : 100;
          }
          break;
      }
    }

    final targets = DietPlanTargets(
      caloriesPerDay: _roundCalories(calories),
      carbsPercentage: carbs,
      proteinPercentage: proteins,
      fatPercentage: fats,
    );
    return targets.normalized();
  }

  int _roundCalories(double value) {
    if (value.isNaN || value.isInfinite) {
      return 1800;
    }
    final rounded = (50 * (value / 50).round()).clamp(1200, 3800);
    return rounded.toInt();
  }

  DietPlan _normalizePlan(
    DietPlan raw,
    DietProfile profile,
    DietPlanTargets recommendedTargets,
  ) {
    final sanitizedTargets = _mergeTargets(raw.targets, recommendedTargets);
    final expectedDays =
        profile.interval == DietPlanInterval.weekly ? 7 : 30;
    final normalizedDays = <DietPlanDay>[];
    final baseDays = raw.days;

    for (var index = 0; index < expectedDays; index++) {
      final sourceDay = index < baseDays.length ? baseDays[index] : null;
      normalizedDays.add(
        _normalizeDay(
          sourceDay ?? _placeholderDay(index, profile.goal),
          index,
          profile,
        ),
      );
    }

    final hydrationCoach = _buildHydrationPlan(profile);
    final mindfulBreak = _buildMindfulBreak(profile);
    final sleepRoutine = _buildSleepRoutine(profile);
    final wellnessDigest = _buildWellnessDigest(
      profile: profile,
      targets: sanitizedTargets,
      hydration: hydrationCoach,
      mindful: mindfulBreak,
      days: normalizedDays,
    );
    final movementRoutine = _buildMovementRoutine(profile);
    final sunlightRoutine = _buildSunlightRoutine(profile);

    return raw.copyWith(
      targets: sanitizedTargets,
      days: List<DietPlanDay>.unmodifiable(normalizedDays),
      hydrationGoal: hydrationCoach.tip,
      hydrationPlan: hydrationCoach,
      mindfulBreakMessage: mindfulBreak.message,
      mindfulBreakHour: mindfulBreak.hour,
      mindfulBreakMinute: mindfulBreak.minute,
      sleepRoutine: sleepRoutine,
      wellnessDigest: wellnessDigest,
      movementRoutine: movementRoutine,
      sunlightRoutine: sunlightRoutine,
    );
  }

  DietPlanTargets _mergeTargets(
    DietPlanTargets aiTargets,
    DietPlanTargets recommended,
  ) {
    final sanitized = aiTargets
        .copyWith(
          caloriesPerDay: aiTargets.caloriesPerDay <= 0
              ? recommended.caloriesPerDay
              : aiTargets.caloriesPerDay,
          carbsPercentage: _clampPercentage(
            aiTargets.carbsPercentage,
            recommended.carbsPercentage,
          ),
          proteinPercentage: _clampPercentage(
            aiTargets.proteinPercentage,
            recommended.proteinPercentage,
          ),
          fatPercentage: _clampPercentage(
            aiTargets.fatPercentage,
            recommended.fatPercentage,
          ),
        )
        .normalized();

    final diff =
        (sanitized.caloriesPerDay - recommended.caloriesPerDay).abs();
    if (diff > 200) {
      return sanitized.copyWith(caloriesPerDay: recommended.caloriesPerDay);
    }
    return sanitized;
  }

  double _clampPercentage(double value, double reference) {
    if (value <= 0) {
      return reference;
    }
    final min = math.max(10, reference - 12);
    final max = math.min(60, reference + 12);
    final clamped = value.clamp(min, max) as double;
    return double.parse(clamped.toStringAsFixed(1));
  }

  DietPlanDay _normalizeDay(
    DietPlanDay day,
    int index,
    DietProfile profile,
  ) {
    final label = day.label.trim().isEmpty ? 'Dia ${index + 1}' : day.label.trim();
    final focus =
        day.focus.trim().isEmpty ? profile.goal.label : day.focus.trim();
    final meals = _ensureCoreMeals(day.meals, profile.goal);
    return day.copyWith(
      label: label,
      focus: focus,
      meals: List<DietPlanMeal>.unmodifiable(meals),
    );
  }

  DietPlanDay _placeholderDay(int index, DietGoal goal) {
    return DietPlanDay(
      label: 'Dia ${index + 1}',
      focus: '${goal.label} com equilíbrio',
      meals: _ensureCoreMeals(const <DietPlanMeal>[], goal),
    );
  }

  List<DietPlanMeal> _ensureCoreMeals(
    List<DietPlanMeal> meals,
    DietGoal goal,
  ) {
    const requiredOrder = <String>[
      'Café da manhã',
      'Lanche da manhã',
      'Almoço',
      'Jantar',
    ];
    final normalizedRequired =
        requiredOrder.map(_normalizeMealKey).toList(growable: false);

    final lookup = <String, DietPlanMeal>{};
    for (final meal in meals) {
      final key = _normalizeMealKey(meal.name);
      lookup[key] = _fillMealDetails(meal);
    }

    final result = <DietPlanMeal>[];
    for (var i = 0; i < requiredOrder.length; i++) {
      final key = normalizedRequired[i];
      final existing = lookup[key];
      if (existing != null) {
        result.add(existing.copyWith(name: requiredOrder[i]));
      } else {
        result.add(_placeholderMeal(requiredOrder[i], goal));
      }
    }

    for (final meal in meals) {
      final key = _normalizeMealKey(meal.name);
      if (!normalizedRequired.contains(key)) {
        result.add(_fillMealDetails(meal));
      }
    }

    return result;
  }

  DietPlanMeal _fillMealDetails(DietPlanMeal meal) {
    String sanitize(String? value, String fallback) {
      if (value == null) {
        return fallback;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }

    return meal.copyWith(
      name: sanitize(meal.name, 'Refeição'),
      description: sanitize(
        meal.description,
        'Personalize esta refeição mantendo o equilíbrio nutricional.',
      ),
      macroFocus: sanitize(
        meal.macroFocus,
        'Equilíbrio entre carboidratos complexos, proteínas magras e fibras.',
      ),
      prepNotes: sanitize(
        meal.prepNotes,
        'Ajuste temperos conforme preferência e mantenha métodos saudáveis.',
      ),
      difficulty: sanitize(meal.difficulty, 'Fácil'),
      duration: sanitize(meal.duration, '15 min'),
    );
  }

  DietPlanMeal _placeholderMeal(String name, DietGoal goal) {
    final focus = switch (goal) {
      DietGoal.loseWeight =>
          'Priorize fibras, proteínas magras e baixo teor de gorduras.',
      DietGoal.gainMass => 'Combine proteínas e carboidratos complexos.',
      DietGoal.maintain => 'Mantenha equilíbrio de macros e porções moderadas.',
      DietGoal.reeducate => 'Varie cores, texturas e inclua alimentos integrais.',
    };

    return DietPlanMeal(
      name: name,
      description:
          'Complete com preparações saudáveis alinhadas ao objetivo informado.',
      macroFocus: focus,
      prepNotes: 'Escolha ingredientes frescos e evite ultraprocessados.',
      ingredients: const <String>[],
      steps: const <String>[],
      difficulty: 'Fácil',
      duration: '15 min',
    );
  }

  String _normalizeMealKey(String value) {
    final lower = value.toLowerCase();
    final normalized = lower
        .replaceAll(RegExp(r'[^a-z0-9áàâãäéèêëíìîïóòôõöúùûüç ]'), '')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
    return normalized.trim();
  }

  double _calculateWeeklyTrend(List<WeightEntry> history) {
    if (history.length < 2) {
      return 0;
    }
    final sorted = List<WeightEntry>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.skip(math.max(0, sorted.length - 3)).toList();
    if (recent.length < 2) {
      return 0;
    }
    final first = recent.first;
    final last = recent.last;
    final days = last.date.difference(first.date).inDays.abs();
    final delta = last.weightKg - first.weightKg;
    if (days == 0) {
      return delta;
    }
    return (delta / days) * 7;
  }

  HydrationPlanInfo _buildHydrationPlan(DietProfile profile) {
    final weightKg = profile.weightKg <= 0 ? 60 : profile.weightKg;
    var totalMl = (weightKg * 35).round();

    switch (profile.activityLevel) {
      case DietActivityLevel.sedentary:
        totalMl += 150;
        break;
      case DietActivityLevel.light:
        totalMl += 300;
        break;
      case DietActivityLevel.moderate:
        totalMl += 450;
        break;
      case DietActivityLevel.intense:
        totalMl += 650;
        break;
    }

    switch (profile.goal) {
      case DietGoal.loseWeight:
        totalMl += 200;
        break;
      case DietGoal.gainMass:
        totalMl += 250;
        break;
      case DietGoal.maintain:
        totalMl += 150;
        break;
      case DietGoal.reeducate:
        totalMl += 100;
        break;
    }

    totalMl = totalMl.clamp(1500, 4500);

    final reminderCount = () {
      switch (profile.activityLevel) {
        case DietActivityLevel.sedentary:
          return 4;
        case DietActivityLevel.light:
          return 5;
        case DietActivityLevel.moderate:
          return 6;
        case DietActivityLevel.intense:
          return 6;
      }
    }();

    final baseSlots = <List<int>>[
      <int>[7, 30],
      <int>[9, 45],
      <int>[12, 0],
      <int>[14, 30],
      <int>[17, 0],
      <int>[19, 30],
      <int>[21, 0],
    ];

    final selectedSlots = baseSlots.take(reminderCount).toList(growable: false);

    final amounts = <int>[];
    var remaining = totalMl;
    for (var index = 0; index < selectedSlots.length; index++) {
      final slotsRemaining = selectedSlots.length - index;
      int amount;
      if (slotsRemaining == 1) {
        amount = remaining;
      } else {
        amount = (remaining / slotsRemaining).round();
        amount = (amount / 50).round() * 50;
        if (amount < 150) {
          amount = 150;
        }
        if (amount > remaining) {
          amount = remaining;
        }
        if (amount < 100 && remaining > 0) {
          amount = math.min(remaining, 100);
        }
        amount = amount.clamp(100, 1200);
      }
      remaining -= amount;
      amounts.add(amount);
    }

    if (remaining > 0 && amounts.isNotEmpty) {
      amounts[amounts.length - 1] += remaining;
      remaining = 0;
    }

    _rebalanceHydrationDistribution(selectedSlots, amounts);

    final reminders = <HydrationReminderSlot>[];
    for (var index = 0; index < selectedSlots.length; index++) {
      final slot = selectedSlots[index];
      final amount = amounts[index];
      final label =
          '${slot[0].toString().padLeft(2, '0')}:${slot[1].toString().padLeft(2, '0')} - $amount ml';
      reminders.add(
        HydrationReminderSlot(
          hour: slot[0],
          minute: slot[1],
          amountMl: amount,
          label: label,
        ),
      );
    }

    final liters = totalMl / 1000;
    final litersLabel = liters
        .toStringAsFixed(liters >= 3 ? 1 : 2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'[\.,]$'), '')
        .replaceAll('.', ',');

    final activityMessage = () {
      switch (profile.activityLevel) {
        case DietActivityLevel.sedentary:
          return 'Levante-se a cada duas horas para beber água e ativar a circulação.';
        case DietActivityLevel.light:
          return 'Aproveite as pausas entre tarefas para beber água e respirar fundo.';
        case DietActivityLevel.moderate:
          return 'Faça pequenas pausas pós-treino para repor líquidos gradualmente.';
        case DietActivityLevel.intense:
          return 'Hidrate-se antes e depois das sessões de treino para acelerar a recuperação.';
      }
    }();

    final goalMessage = () {
      switch (profile.goal) {
        case DietGoal.loseWeight:
          return 'A hidratação ajuda a controlar o apetite e manter o metabolismo ativo.';
        case DietGoal.gainMass:
          return 'Combinar água com refeições ricas em proteína apoia a recuperação muscular.';
        case DietGoal.maintain:
          return 'Manter o consumo estável garante energia e foco durante o dia.';
        case DietGoal.reeducate:
          return 'Beber água ao longo do dia reforça a saciedade e hábitos saudáveis.';
      }
    }();

    final tip =
        'Meta hídrica diária: ${litersLabel.isEmpty ? liters.toStringAsFixed(1).replaceAll('.', ',') : litersLabel} L (${totalMl} ml). '
        '$activityMessage $goalMessage';

    return HydrationPlanInfo(
      totalMl: totalMl,
      tip: tip,
      reminders: List<HydrationReminderSlot>.unmodifiable(reminders),
    );
  }

  void _rebalanceHydrationDistribution(
    List<List<int>> slots,
    List<int> amounts,
  ) {
    const minSlotMl = 120;
    const donorReserve = 30;

    if (amounts.isEmpty) {
      return;
    }

    if (amounts.length == 1) {
      amounts[0] = math.max(amounts[0], minSlotMl);
      return;
    }

    for (var index = amounts.length - 1; index >= 0; index--) {
      if (amounts[index] >= minSlotMl) {
        continue;
      }

      var deficit = minSlotMl - amounts[index];
      for (var donor = 0; donor < amounts.length && deficit > 0; donor++) {
        if (donor == index) {
          continue;
        }

        final available = amounts[donor] - (minSlotMl + donorReserve);
        if (available <= 0) {
          continue;
        }

        final transfer = math.min(available, deficit);
        amounts[donor] -= transfer;
        amounts[index] += transfer;
        deficit -= transfer;
      }

      if (amounts[index] >= minSlotMl) {
        continue;
      }

      if (amounts.length <= 1) {
        break;
      }

      final fallbackIndex = index == 0 ? 1 : index - 1;
      if (fallbackIndex < amounts.length) {
        amounts[fallbackIndex] += amounts[index];
      }
      amounts.removeAt(index);
      slots.removeAt(index);
    }
  }

  SleepRoutineInfo _buildSleepRoutine(DietProfile profile) {
    final bedtimeHour = profile.sleepWindow.targetHour;
    final bedtimeMinute = profile.sleepWindow.targetMinute;
    final bedtimeLabel =
        '${bedtimeHour.toString().padLeft(2, '0')}:${bedtimeMinute.toString().padLeft(2, '0')}';

    final reminderDate = DateTime(0, 1, 1, bedtimeHour, bedtimeMinute)
        .subtract(const Duration(minutes: 30));
    final reminderHour = reminderDate.hour;
    final reminderMinute = reminderDate.minute;

    final goalTip = () {
      switch (profile.goal) {
        case DietGoal.loseWeight:
          return 'Prepare um copo de água e deixe o café da manhã planejado para evitar escolhas impulsivas.';
        case DietGoal.gainMass:
          return 'Garanta um lanche leve com proteína, caso faça parte do seu plano, e organize o treino do dia seguinte.';
        case DietGoal.maintain:
          return 'Revise a agenda do dia seguinte e mantenha o quarto ventilado para preservar a qualidade do sono.';
        case DietGoal.reeducate:
          return 'Separe frutas ou chás calmantes e registre rapidamente qualquer aprendizado do dia.';
      }
    }();

    final tips = <String>[
      'Reduza luzes e telas brilhantes 30 minutos antes de $bedtimeLabel.',
      'Faça respirações profundas ou alongamentos leves para sinalizar o descanso ao corpo.',
      goalTip,
    ];

    final message = profile.sleepCoachEnabled
        ? 'Desacelere: ajuste o ambiente e hidrate-se para dormir às $bedtimeLabel com mais qualidade.'
        : 'Ative o coach de sono para receber lembretes noturnos personalizados.';

    return SleepRoutineInfo(
      enabled: profile.sleepCoachEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      message: message,
      windDownSummary: profile.sleepWindow.summary,
      windDownTips: List<String>.unmodifiable(tips),
    );
  }

  WellnessDigestInfo _buildWellnessDigest({
    required DietProfile profile,
    required DietPlanTargets targets,
    required HydrationPlanInfo hydration,
    required _MindfulBreakSchedule mindful,
    required List<DietPlanDay> days,
  }) {
    final normalizedGoal = profile.goal.label.toLowerCase();
    final summary =
        'Plano focado em $normalizedGoal respeitando um ${profile.metabolicProfileLabel.toLowerCase()}.';

    final macroHighlight =
        '${targets.caloriesPerDay} kcal • C ${targets.carbsPercentage}% • P ${targets.proteinPercentage}% • G ${targets.fatPercentage}%';

    final hydrationHighlight = hydration.hasReminders
        ? '${hydration.totalMl} ml distribuídos em ${hydration.reminders.length} lembretes.'
        : '${hydration.totalMl} ml recomendados ao longo do dia.';

    var totalMeals = 0;
    var countedDays = 0;
    for (final day in days) {
      if (day.meals.isNotEmpty) {
        totalMeals += day.meals.length;
        countedDays++;
      }
    }
    final avgMeals = countedDays == 0 ? 0.0 : totalMeals / countedDays;
    final mealHighlight = countedDays == 0
        ? 'As refeições serão definidas conforme o plano for atualizado.'
        : '${days.length} dias com aproximadamente ${avgMeals.toStringAsFixed(1).replaceAll('.0', '')} refeições principais.';

    final mindfulLabel =
        '${mindful.hour.toString().padLeft(2, '0')}:${mindful.minute.toString().padLeft(2, '0')}';

    final highlights = <String>[
      'Metas diárias: $macroHighlight.',
      'Hidratação orientada: $hydrationHighlight',
      'Pausa de bem-estar às $mindfulLabel para manter postura e foco.',
      mealHighlight,
    ];

    final cleanedHighlights = highlights
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final hoursBefore =
        profile.interval == DietPlanInterval.weekly ? 12 : 24;

    final callToAction =
        'Revise o resumo na véspera do check-in para decidir se mantém ou ajusta a estratégia.';

    return WellnessDigestInfo(
      enabled: profile.wellnessDigestEnabled,
      summary: summary,
      highlights: List<String>.unmodifiable(cleanedHighlights),
      callToAction: callToAction,
      hoursBeforeCheckIn: hoursBefore,
    );
  }

  MovementBreakInfo _buildMovementRoutine(DietProfile profile) {
    if (!profile.movementCoachEnabled) {
      return const MovementBreakInfo(
        enabled: false,
        summary: '',
        slots: <MovementBreakSlot>[],
        tips: <String>[],
      );
    }

    final templates = <Map<String, dynamic>>[
      <String, dynamic>{
        'hour': 10,
        'minute': 30,
        'focus': 'Alongamento de cervical e ombros',
      },
      <String, dynamic>{
        'hour': 14,
        'minute': 45,
        'focus': 'Mobilidade de quadril e coluna',
      },
      <String, dynamic>{
        'hour': 17,
        'minute': 30,
        'focus': 'Caminhada leve ou subir escadas',
      },
    ];

    final slotCount = switch (profile.activityLevel) {
      DietActivityLevel.sedentary => 3,
      DietActivityLevel.light => 3,
      DietActivityLevel.moderate => 2,
      DietActivityLevel.intense => 2,
    };

    final baseDuration = switch (profile.activityLevel) {
      DietActivityLevel.sedentary => 7,
      DietActivityLevel.light => 6,
      DietActivityLevel.moderate => 5,
      DietActivityLevel.intense => 4,
    };

    final slots = <MovementBreakSlot>[];
    for (var i = 0; i < slotCount && i < templates.length; i++) {
      final template = templates[i];
      final hour = template['hour'] as int;
      final minute = template['minute'] as int;
      final focus = template['focus'] as String;
      final extra = i == templates.length - 1 ? 1 : 0;
      final duration = (baseDuration + extra).clamp(3, 12);
      slots.add(
        MovementBreakSlot(
          hour: hour,
          minute: minute,
          durationMinutes: duration,
          activity: '$focus por ${duration} minuto(s).',
        ),
      );
    }

    final summary =
        'Inclua ${slotCount == 1 ? 'uma pausa ativa diária' : '$slotCount pausas ativas diárias'} para reduzir rigidez e manter energia.';
    final tips = <String>[
      'Programe um alarme e afaste-se da tela para realizar a pausa completa.',
      'Associe a pausa a um copo de água para reforçar a hidratação.',
      if (profile.goal == DietGoal.loseWeight)
        'Use movimentos que elevem levemente a frequência cardíaca para estimular o gasto calórico.',
      if (profile.goal == DietGoal.gainMass)
        'Inclua exercícios isométricos rápidos (como prancha ou agachamento isométrico) para ativar musculatura.',
    ].where((tip) => tip.isNotEmpty).toList(growable: false);

    return MovementBreakInfo(
      enabled: true,
      summary: summary,
      slots: List<MovementBreakSlot>.unmodifiable(slots),
      tips: tips,
    );
  }

  SunlightExposureInfo _buildSunlightRoutine(DietProfile profile) {
    if (!profile.sunlightCoachEnabled) {
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

    var reminderHour = switch (profile.sleepWindow) {
      DietSleepWindow.early => 8,
      DietSleepWindow.regular => 9,
      DietSleepWindow.late => 10,
    };
    if (profile.activityLevel == DietActivityLevel.intense) {
      reminderHour = math.max(7, reminderHour - 1);
    }

    final reminderMinute = 15;

    var duration = switch (profile.goal) {
      DietGoal.loseWeight => 22,
      DietGoal.gainMass => 18,
      DietGoal.maintain => 16,
      DietGoal.reeducate => 20,
    };
    if (profile.activityLevel == DietActivityLevel.sedentary) {
      duration += 3;
    }
    if (profile.activityLevel == DietActivityLevel.intense) {
      duration = math.max(12, duration - 4);
    }
    duration = duration.clamp(12, 30);

    final benefits = <String>[
      'Estimula a produção de vitamina D e fortalece o sistema imune.',
      'Regula o relógio biológico e melhora a qualidade do sono.',
      if (profile.goal == DietGoal.loseWeight)
        'Ajuda a controlar hormônios ligados ao apetite e saciedade.',
      if (profile.goal == DietGoal.gainMass)
        'Favorece a síntese proteica ao apoiar os ritmos hormonais.',
    ];

    final cautions = <String>[
      'Use protetor solar nas áreas expostas se ultrapassar 15 minutos.',
      'Evite a faixa de maior índice UV (12h às 15h) e busque sombra parcial se necessário.',
    ];

    final message =
        'Momento de receber sol leve por $duration minuto(s). Busque uma área ventilada e mantenha-se hidratado.';
    return SunlightExposureInfo(
      enabled: true,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      durationMinutes: duration,
      message: message,
      benefits: benefits,
      cautions: cautions,
    );
  }

  _MindfulBreakSchedule _buildMindfulBreak(DietProfile profile) {
    var hour = 15;
    var minute = 0;

    if (profile.cookingStyle == DietCookingStyle.batchAndFreeze) {
      hour = 11;
      minute = 30;
    } else if (profile.activityLevel == DietActivityLevel.intense) {
      hour = 17;
      minute = 0;
    }

    final message = () {
      switch (profile.goal) {
        case DietGoal.loseWeight:
          return 'Alongue-se por 5 minutos, hidrate-se e faça três respirações profundas para retomar o foco.';
        case DietGoal.gainMass:
          return 'Use a pausa para mobilidade leve, alongamento e um copo de água para favorecer a recuperação.';
        case DietGoal.maintain:
          return 'Interrompa a rotina por alguns minutos, movimente o corpo e ajuste a postura antes de continuar.';
        case DietGoal.reeducate:
          return 'Respire fundo, alongue ombros e pescoço e aproveite para planejar a próxima refeição equilibrada.';
      }
    }();

    return _MindfulBreakSchedule(hour: hour, minute: minute, message: message);
  }
}

class _MindfulBreakSchedule {
  const _MindfulBreakSchedule({
    required this.hour,
    required this.minute,
    required this.message,
  });

  final int hour;
  final int minute;
  final String message;
}
