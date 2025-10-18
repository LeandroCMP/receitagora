import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';
import 'package:receitagora/services/nutrition/nutrition_plan_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class NutritionPlanController extends GetxController {
  NutritionPlanController({
    required this.service,
    required this.sessionService,
  });

  final NutritionPlanService service;
  final SessionService sessionService;

  late final TextEditingController heightController;
  late final TextEditingController weightController;
  late final TextEditingController notesController;
  late final TextEditingController checkInController;

  final Rx<DietActivityLevel> activityLevel = DietActivityLevel.sedentary.obs;
  final Rx<DietGoal> goal = DietGoal.reeducate.obs;
  final Rx<DietPlanInterval> interval = DietPlanInterval.weekly.obs;
  final Rx<DietCookingStyle> cookingStyle = DietCookingStyle.cookDaily.obs;
  final RxBool prefersBrazilianCuisine = true.obs;
  final RxBool prefersSeasonalProduce = false.obs;
  final RxString snackFrequency = 'Moderado'.obs;
  final RxDouble metabolicEase = 2.0.obs;

  final RxBool isGenerating = false.obs;
  final RxBool isRecording = false.obs;
  final Rxn<NutritionPlan> currentPlan = Rxn<NutritionPlan>();

  StreamSubscription<NutritionPlan?>? _planSubscription;

  static const List<String> snackOptions = <String>[
    'Baixa',
    'Moderado',
    'Alta',
  ];

  @override
  void onInit() {
    super.onInit();
    heightController = TextEditingController();
    weightController = TextEditingController();
    notesController = TextEditingController();
    checkInController = TextEditingController();
    _planSubscription = service.watchCurrentPlan().listen(_applyPlan);
  }

  @override
  void onClose() {
    heightController.dispose();
    weightController.dispose();
    notesController.dispose();
    checkInController.dispose();
    _planSubscription?.cancel();
    super.onClose();
  }

  bool get hasPlan => currentPlan.value != null;
  bool get isCheckInOverdue => currentPlan.value?.isCheckInOverdue ?? false;
  bool get needsAdjustment => currentPlan.value?.needsAdjustment ?? false;

  String get intervalLabel => interval.value.label;
  String get cookingStyleLabel => cookingStyle.value.label;

  Future<void> generatePlan() async {
    final height = _parseDouble(heightController.text.trim());
    final weight = _parseDouble(weightController.text.trim());
    if (height == null || height <= 0 || weight == null || weight <= 0) {
      AppSnackbar.warning(
        title: 'Informe altura e peso válidos',
        message: 'Preencha altura e peso atuais para personalizar o cardápio.',
      );
      return;
    }

    final easeScore = metabolicEase.value.round();
    final clampedEase = easeScore < 0
        ? 0
        : easeScore > 5
            ? 5
            : easeScore;

    final profile = DietProfile(
      heightCm: height,
      weightKg: weight,
      activityLevel: activityLevel.value,
      metabolicEase: clampedEase,
      goal: goal.value,
      interval: interval.value,
      cookingStyle: cookingStyle.value,
      prefersBrazilianCuisine: prefersBrazilianCuisine.value,
      additionalNotes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      prefersSeasonalProduce: prefersSeasonalProduce.value,
      snackFrequency: snackFrequency.value,
    );

    if (isGenerating.value) {
      return;
    }

    var overlayShown = false;
    try {
      if (!(Get.isDialogOpen ?? false)) {
        overlayShown = true;
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }
      isGenerating.value = true;
      final plan = await service.generatePlan(profile);
      currentPlan.value = plan;
      AppSnackbar.success(
        title: 'Plano atualizado',
        message: 'Seu cardápio premium foi gerado com base nas informações informadas.',
      );
    } on AppException catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível gerar o plano',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message: 'Não conseguimos gerar o cardápio agora. Tente novamente em instantes.',
      );
    } finally {
      isGenerating.value = false;
      if (overlayShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }

  Future<void> recordWeighIn() async {
    final value = _parseDouble(checkInController.text.trim());
    if (value == null || value <= 0) {
      AppSnackbar.warning(
        title: 'Informe o peso atualizado',
        message: 'Digite seu peso atual para registrar o resultado da semana ou mês.',
      );
      return;
    }

    if (isRecording.value) {
      return;
    }

    var overlayShown = false;

    isRecording.value = true;
    try {
      if (!(Get.isDialogOpen ?? false)) {
        overlayShown = true;
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }

      final plan = await service.recordWeighIn(value);
      currentPlan.value = plan;
      checkInController.clear();
      final message = plan.needsAdjustment
          ? 'Seu peso não evoluiu como esperado. Ajustaremos o próximo cardápio para buscar resultados melhores.'
          : 'Excelente! Vamos manter a estratégia atual nas próximas sugestões.';
      AppSnackbar.info(
        title: 'Check-in registrado',
        message: message,
      );
    } on AppException catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível registrar o peso',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message: 'Não conseguimos registrar o peso agora. Tente novamente em instantes.',
      );
    } finally {
      isRecording.value = false;
      if (overlayShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }

  void setActivityLevel(DietActivityLevel level) => activityLevel.value = level;
  void setGoal(DietGoal value) => goal.value = value;
  void setInterval(DietPlanInterval value) => interval.value = value;
  void setCookingStyle(DietCookingStyle value) => cookingStyle.value = value;

  void toggleBrazilianCuisine(bool value) => prefersBrazilianCuisine.value = value;
  void toggleSeasonalProduce(bool value) => prefersSeasonalProduce.value = value;
  void setSnackFrequency(String value) => snackFrequency.value = value;

  void _applyPlan(NutritionPlan? plan) {
    currentPlan.value = plan;
    if (plan == null) {
      return;
    }

    final profile = plan.profile;
    heightController.text = profile.heightCm.toStringAsFixed(1);
    weightController.text = profile.weightKg.toStringAsFixed(1);
    notesController.text = profile.additionalNotes ?? '';
    activityLevel.value = profile.activityLevel;
    goal.value = profile.goal;
    interval.value = profile.interval;
    cookingStyle.value = profile.cookingStyle;
    prefersBrazilianCuisine.value = profile.prefersBrazilianCuisine;
    prefersSeasonalProduce.value = profile.prefersSeasonalProduce;
    snackFrequency.value = profile.snackFrequency;
    metabolicEase.value = profile.metabolicEase.toDouble();
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) {
      return null;
    }
    final sanitized = value.replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

}
