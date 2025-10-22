import 'dart:async';

import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/recipe_finder/recipe_finder_controller.dart';
import 'package:receitagora/modules/recipe_finder/recipe_results_page.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';
import 'package:receitagora/modules/shopping_list/shopping_list_detail_controller.dart';

class RecipeHistoryController extends GetxController {
  RecipeHistoryController({
    required this.historyService,
    required this.shoppingListService,
  });

  final RecipeHistoryService historyService;
  final ShoppingListService shoppingListService;

  final RxList<RecipeHistoryEntry> entries = <RecipeHistoryEntry>[].obs;
  final RxBool isClearing = false.obs;
  final RxBool isCreatingList = false.obs;

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

  Future<void> createShoppingList(RecipeHistoryEntry entry) async {
    if (isCreatingList.value) {
      return;
    }

    isCreatingList.value = true;
    try {
      final result = await historyService.fetchLastResult(entry.cacheKey);
      if (result == null) {
        await historyService.removeEntry(entry.cacheKey);
        AppSnackbar.info(
          title: 'Combinação indisponível',
          message:
              'Os detalhes desta busca foram removidos. Gere uma nova combinação para montar a lista.',
        );
        return;
      }

      final list = await shoppingListService.createFromHistory(
        historyResult: result,
        title: _titleFromEntry(entry),
        allowDuplicates: false,
      );

      AppSnackbar.success(
        title: 'Lista pronta',
        message: 'Organizamos os ingredientes das receitas em uma lista inteligente.',
      );

      await Future<void>.delayed(const Duration(milliseconds: 250));
      Get.toNamed(
        AppRoutes.shoppingListDetail,
        arguments: ShoppingListDetailArgs(listId: list.id),
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível criar a lista',
        message: 'Tente novamente em instantes.',
      );
    } finally {
      isCreatingList.value = false;
    }
  }

  String _titleFromEntry(RecipeHistoryEntry entry) {
    final ingredients = entry.ingredients;
    if (ingredients.isEmpty) {
      return 'Lista ${_formatDate(entry.timestamp)}';
    }
    if (ingredients.length <= 3) {
      return 'Compras: ${ingredients.join(', ')}';
    }
    return 'Compras: ${ingredients.take(3).join(', ')} +${ingredients.length - 3}';
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
