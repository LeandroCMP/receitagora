import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/ingredient_lab/ingredient_lab_report.dart';
import 'package:receitagora/models/ingredient_lab/ingredient_lab_request.dart';
import 'package:receitagora/services/ingredient_lab/ingredient_lab_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class IngredientLabController extends GetxController {
  IngredientLabController({
    required this.labService,
    required this.sessionService,
  });

  final IngredientLabService labService;
  final SessionService sessionService;

  late final TextEditingController ingredientController;
  late final TextEditingController contextController;
  late final TextEditingController goalController;
  late final TextEditingController notesController;
  late final TextEditingController availableInputController;
  late final TextEditingController restrictionInputController;

  final RxList<String> availableItems = <String>[].obs;
  final RxList<String> restrictedItems = <String>[].obs;
  final RxBool isRunning = false.obs;
  final Rxn<IngredientLabReport> report = Rxn<IngredientLabReport>();

  @override
  void onInit() {
    super.onInit();
    ingredientController = TextEditingController();
    contextController = TextEditingController();
    goalController = TextEditingController();
    notesController = TextEditingController();
    availableInputController = TextEditingController();
    restrictionInputController = TextEditingController();

    final user = sessionService.user;
    if (user?.allergies.isNotEmpty == true) {
      restrictedItems.assignAll(user!.allergies);
    }
  }

  @override
  void onClose() {
    ingredientController.dispose();
    contextController.dispose();
    goalController.dispose();
    notesController.dispose();
    availableInputController.dispose();
    restrictionInputController.dispose();
    super.onClose();
  }

  void addAvailableItem([String? value]) {
    final raw = (value ?? availableInputController.text).trim();
    if (raw.isEmpty) {
      return;
    }
    final normalized = _normalizeEntry(raw);
    if (!availableItems.contains(normalized)) {
      availableItems.add(normalized);
    }
    availableInputController.clear();
  }

  void removeAvailableItem(String item) {
    availableItems.remove(item);
  }

  void addRestriction([String? value]) {
    final raw = (value ?? restrictionInputController.text).trim();
    if (raw.isEmpty) {
      return;
    }
    final normalized = _normalizeEntry(raw);
    if (!restrictedItems.contains(normalized)) {
      restrictedItems.add(normalized);
    }
    restrictionInputController.clear();
  }

  void removeRestriction(String item) {
    restrictedItems.remove(item);
  }

  Future<void> runLaboratory() async {
    final ingredient = ingredientController.text.trim();
    if (ingredient.isEmpty) {
      AppSnackbar.warning(
        title: 'Informe o ingrediente principal',
        message: 'Digite qual ingrediente você deseja substituir ou estudar no laboratório.',
      );
      return;
    }

    final request = IngredientLabRequest(
      ingredient: ingredient,
      dishContext: contextController.text.trim().isEmpty
          ? null
          : contextController.text.trim(),
      desiredOutcome: goalController.text.trim().isEmpty
          ? null
          : goalController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      availableIngredients: availableItems,
      restrictions: restrictedItems,
    );

    var overlayShown = false;
    try {
      if (!(Get.isDialogOpen ?? false)) {
        overlayShown = true;
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }
      isRunning.value = true;
      final result = await labService.runLaboratory(request);
      report.value = result;
    } on AppException catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível concluir o laboratório',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Não conseguimos gerar o relatório agora. Tente novamente em instantes.',
      );
    } finally {
      isRunning.value = false;
      if (overlayShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }

  String _normalizeEntry(String value) {
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
