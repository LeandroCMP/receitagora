import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';

import 'shopping_list_detail_controller.dart';

class ShoppingListsController extends GetxController {
  ShoppingListsController({
    required this.shoppingListService,
    required this.historyService,
  });

  final ShoppingListService shoppingListService;
  final RecipeHistoryService historyService;

  final RxList<ShoppingList> lists = <ShoppingList>[].obs;
  final RxBool isCreating = false.obs;

  StreamSubscription<List<ShoppingList>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    lists.assignAll(shoppingListService.lists);
    _subscription =
        shoppingListService.listsStream.listen(lists.assignAll);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void openList(ShoppingList list) {
    Get.toNamed(
      AppRoutes.shoppingListDetail,
      arguments: ShoppingListDetailArgs(listId: list.id),
    );
  }

  void openHistoryShortcut() {
    Get.toNamed(AppRoutes.recipeHistory);
  }

  Future<void> promptCreationFromHistory() async {
    final entries = historyService.history;
    if (entries.isEmpty) {
      AppSnackbar.info(
        title: 'Histórico vazio',
        message: 'Faça uma nova busca de receitas para montar uma lista.',
      );
      return;
    }

    final selected = await Get.bottomSheet<RecipeHistoryEntry>(
      _HistorySelectionSheet(entries: entries),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );

    if (selected == null) {
      return;
    }

    await createFromHistory(selected);
  }

  Future<void> createFromHistory(RecipeHistoryEntry entry) async {
    if (isCreating.value) {
      return;
    }
    isCreating.value = true;
    try {
      final result = await historyService.fetchLastResult(entry.cacheKey);
      if (result == null) {
        await historyService.removeEntry(entry.cacheKey);
        AppSnackbar.info(
          title: 'Busca expirada',
          message: 'Os detalhes dessa combinação não estão mais disponíveis.',
        );
        return;
      }

      final list = await shoppingListService.createFromHistory(
        historyResult: result,
        title: _titleFromEntry(entry),
        allowDuplicates: false,
      );

      AppSnackbar.success(
        title: 'Lista criada',
        message: 'Itens organizados por receita para facilitar as compras.',
      );

      Get.toNamed(
        AppRoutes.shoppingListDetail,
        arguments: ShoppingListDetailArgs(listId: list.id),
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Falha ao criar lista',
        message: 'Não conseguimos montar a lista agora. Tente novamente.',
      );
    } finally {
      isCreating.value = false;
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

  String _formatDate(DateTime timestamp) {
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _HistorySelectionSheet extends StatelessWidget {
  const _HistorySelectionSheet({required this.entries});

  final List<RecipeHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escolha uma combinação recente',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final formatted = _formatTimestamp(entry.timestamp);
                  final title = entry.ingredients.isEmpty
                      ? 'Combinação sem ingredientes'
                      : entry.ingredients.length <= 3
                          ? entry.ingredients.join(', ')
                          : '${entry.ingredients.take(3).join(', ')} +${entry.ingredients.length - 3}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(title),
                    subtitle: Text('$formatted • ${entry.totalRecipes} sugestão${entry.totalRecipes == 1 ? '' : 's'}'),
                    onTap: () => Get.back(result: entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
