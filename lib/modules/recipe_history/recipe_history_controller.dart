import 'dart:async';

import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/recipe_finder/recipe_finder_controller.dart';
import 'package:receitagora/modules/recipe_finder/recipe_results_page.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';

class RecipeHistoryController extends GetxController {
  RecipeHistoryController({required this.historyService});

  final RecipeHistoryService historyService;

  final RxList<RecipeHistoryEntry> entries = <RecipeHistoryEntry>[].obs;
  final RxBool isClearing = false.obs;

  StreamSubscription<List<RecipeHistoryEntry>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    entries.assignAll(historyService.history);
    _subscription = historyService.historyStream.listen(entries.assignAll);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> openEntry(RecipeHistoryEntry entry) async {
    final result = await historyService.fetchLastResult(entry.cacheKey);
    if (result == null) {
      await historyService.removeEntry(entry.cacheKey);
      AppSnackbar.info(
        title: 'Conteúdo indisponível',
        message:
            'Não encontramos os detalhes dessa busca. Ela foi removida do histórico.',
      );
      return;
    }

    if (Get.isRegistered<RecipeFinderController>()) {
      final controller = Get.find<RecipeFinderController>();
      controller.ingredients
        ..clear()
        ..addAll(result.ingredients);
    }

    final formatted = _formatTimestamp(result.timestamp);
    await Get.toNamed(
      AppRoutes.recipeResults,
      arguments: RecipeResultsArgs(
        recipes: result.recipes,
        ingredients: result.ingredients,
        message: 'Sugestões recuperadas da busca feita em $formatted.',
      ),
    );
  }

  Future<void> removeEntry(RecipeHistoryEntry entry) async {
    await historyService.removeEntry(entry.cacheKey);
    AppSnackbar.info(
      title: 'Busca removida',
      message: 'Esta combinação saiu do histórico.',
    );
  }

  Future<void> clearHistory() async {
    if (entries.isEmpty) {
      return;
    }
    isClearing.value = true;
    try {
      await historyService.clearHistory();
      AppSnackbar.info(
        title: 'Histórico limpo',
        message: 'Suas últimas buscas foram removidas.',
      );
    } finally {
      isClearing.value = false;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }
}
