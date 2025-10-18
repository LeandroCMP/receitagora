import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';
import 'package:receitagora/services/openai/openai_service.dart';
import 'package:receitagora/services/session/session_service.dart';

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
    final userPrompt = _buildPlanPrompt(profile);
    final response = await openAIService.requestStructuredJson(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.55,
    );

    final plan = DietPlan.fromMap(response);
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

  Future<NutritionPlan> regeneratePlan() async {
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

    final current = await fetchCurrentPlan();
    if (current == null) {
      throw const AppException('Gere um cardápio inicial antes de solicitar uma nova variação.');
    }

    final systemPrompt =
        'Você é o Chef Nutricional do Receitagora. Crie cardápios brasileiros equilibrados, com foco em segurança, variedade e viabilidade para o dia a dia.';
    final userPrompt = _buildPlanPrompt(current.profile, previousPlan: current);
    final response = await openAIService.requestStructuredJson(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.65,
    );

    final plan = DietPlan.fromMap(response);
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

  Future<NutritionPlan> recordWeighIn(double weightKg) async {
    if (weightKg <= 0) {
      throw const AppException('Informe um peso válido para registrar o check-in.');
    }
    final current = await fetchCurrentPlan();
    if (current == null) {
      throw const AppException('Nenhum plano encontrado. Gere um cardápio antes de registrar o peso.');
    }

    final doc = _planDocument();
    if (doc == null) {
      throw const AppException('Não foi possível localizar o documento do plano.');
    }

    final now = DateTime.now();
    final history = List<WeightEntry>.from(current.weightHistory)
      ..add(WeightEntry(date: now, weightKg: weightKg));

    final updatedProfile = current.profile.copyWith(weightKg: weightKg);
    final needsAdjustment = _shouldAdjustStrategy(
      goal: current.profile.goal,
      previousWeight: current.lastWeighInKg,
      currentWeight: weightKg,
    );

    final updatedPlan = current.copyWith(
      profile: updatedProfile,
      lastWeighInKg: weightKg,
      weightHistory: List<WeightEntry>.unmodifiable(history),
      nextCheckInAt: now.add(updatedProfile.interval.duration),
      needsAdjustment: needsAdjustment,
    );

    await doc.set(_serializePlan(updatedPlan), SetOptions(merge: true));
    return updatedPlan;
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
  }) {
    final delta = double.parse((currentWeight - previousWeight).toStringAsFixed(1));
    switch (goal) {
      case DietGoal.loseWeight:
        return !(currentWeight < previousWeight - 0.3);
      case DietGoal.gainMass:
        return !(currentWeight > previousWeight + 0.3);
      case DietGoal.maintain:
        return delta.abs() > 0.5;
      case DietGoal.reeducate:
        return delta.abs() < 0.3;
    }
  }

  String _buildPlanPrompt(
    DietProfile profile, {
    NutritionPlan? previousPlan,
  }) {
    final user = sessionService.user;
    final buffer = StringBuffer();
    buffer.writeln('Monte um plano ${profile.interval.label.toLowerCase()} com foco em ${profile.goal.label.toLowerCase()}.');
    buffer.writeln('Dados biométricos: altura ${profile.heightCm.toStringAsFixed(1)} cm, peso ${profile.weightKg.toStringAsFixed(1)} kg, IMC ${profile.bmi}.');
    buffer.writeln('Nível de atividade: ${profile.activityLevel.label}.');
    buffer.writeln('Facilidade para emagrecer (autoavaliação 0-5): ${profile.metabolicEase}.');
    buffer.writeln('Estilo de preparo preferido: ${profile.cookingStyle.label}.');
    buffer.writeln('Planejamento ${profile.interval == DietPlanInterval.weekly ? 'de 7 dias' : 'de 30 dias'} com refeições brasileiras modernas.');
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
      if (previousPlan.needsAdjustment) {
        buffer.writeln('O usuário relatou que o último plano não gerou o resultado esperado. Ajuste estratégia e variedade.');
      } else {
        buffer.writeln('O usuário deseja uma nova variação mantendo o objetivo atual, explorando combinações diferentes.');
      }
      buffer.writeln('Evite repetir as mesmas combinações da última semana e proponha novidades mantendo equilíbrio nutricional.');
    } else {
      buffer.writeln('Entregue um cardápio inédito baseado nesses dados.');
    }

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
        '        {"name": "Refeição", "description": "string", "calories": number, "macroFocus": "string", "prepNotes": "string",');
    buffer.writeln('         "ingredients": ["string"...], "steps": ["string"...], "difficulty": "string", "duration": "string"}');
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln('  "shoppingList": [');
    buffer.writeln('    {"category": "string", "item": "string", "quantity": "string", "notes": "string"}');
    buffer.writeln('  ],');
    buffer.writeln('  "followUpTips": ["string"...]');
    buffer.writeln('}');
    buffer.writeln('Utilize alimentos acessíveis no Brasil, com combinações sazonais quando aplicável e versões possíveis de congelar quando o usuário optar por produzir em lote.');
    buffer.writeln('Inclua variações de café da manhã, almoço, jantar e lanches coerentes com o objetivo ${profile.goal.promptKeyword}.');
    buffer.writeln('Forneça ingredientes detalhados e um modo de preparo passo a passo claro para cada refeição, com duração média e nível de dificuldade compatíveis com o perfil informado.');

    return buffer.toString();
  }
}
