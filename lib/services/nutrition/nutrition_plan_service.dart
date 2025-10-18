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
    );

    await doc.set(_serializePlan(updatedPlan), SetOptions(merge: true));
    return updatedPlan;
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
      'weightHistory': plan.weightHistory
          .map((entry) => <String, dynamic>{
                'date': Timestamp.fromDate(entry.date),
                'weightKg': entry.weightKg,
              })
          .toList(),
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
    buffer.writeln('Facilidade para emagrecer (autoavaliação 0-5): ${profile.metabolicEase}.');
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

    return raw.copyWith(
      targets: sanitizedTargets,
      days: List<DietPlanDay>.unmodifiable(normalizedDays),
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
}
