import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';

import 'shopping_list_detail_controller.dart';

class ShoppingListDetailPage extends GetView<ShoppingListDetailController> {
  const ShoppingListDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final list = controller.list.value;
          return Text(list?.title ?? 'Lista de compras');
        }),
        actions: [
          Obx(() {
            final isSharing = controller.isSharing.value;
            return IconButton(
              icon: isSharing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_outlined),
              tooltip: 'Compartilhar lista',
              onPressed: isSharing ? null : controller.shareList,
            );
          }),
          _ListOptionsMenu(controller: controller),
          const SizedBox(width: 12),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 720,
                topPadding: 28,
                bottomPadding: 32,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: Obx(() {
                  final list = controller.list.value;
                  if (list == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final surfaces = theme.extension<ReceitagoraSurfaceColors>();

                  return SingleChildScrollView(
                    padding: layout.padding,
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: layout.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ListMetadataCard(
                              theme: theme,
                              surfaces: surfaces,
                              list: list,
                              onEditNote: () => _showNoteDialog(context),
                            ),
                            const SizedBox(height: 20),
                            _ViewModeSelector(
                              controller: controller,
                              theme: theme,
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final mode = controller.viewMode.value;
                              if (mode == ShoppingListViewMode.market) {
                                final sections = controller.buildMarketSections();
                                return _MarketView(
                                  controller: controller,
                                  theme: theme,
                                  surfaces: surfaces,
                                  sections: sections,
                                );
                              }
                              return _RecipeView(
                                controller: controller,
                                theme: theme,
                                surfaces: surfaces,
                                list: list,
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    final list = controller.list.value;
    if (list == null) {
      return;
    }
    final theme = Theme.of(context);
    final textController = TextEditingController(text: list.note ?? '');
    final result = await Get.dialog<String?>(
      AlertDialog(
        title: const Text('Observações da lista'),
        content: TextField(
          controller: textController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Adicione lembretes importantes, substituições ou observações para quem for às compras.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: textController.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
      barrierColor: theme.colorScheme.scrim.withOpacity(0.35),
    );

    if (result != null) {
      await controller.updateNote(result.isEmpty ? null : result);
    }
  }
}

class _ListMetadataCard extends StatelessWidget {
  const _ListMetadataCard({
    required this.theme,
    required this.surfaces,
    required this.list,
    required this.onEditNote,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final ShoppingList list;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final remaining = list.totalItems - list.completedItems;
    final formattedCreated = _formatDate(list.createdAt);
    final formattedUpdated = _formatDate(list.updatedAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Criada em $formattedCreated • Atualizada em $formattedUpdated',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.primaryContainer.withOpacity(0.35),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      remaining <= 0
                          ? Icons.check_circle_outline
                          : Icons.shopping_basket_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        remaining <= 0
                            ? 'Tudo pronto! Todos os itens desta lista foram marcados.'
                            : 'Faltam $remaining item${remaining == 1 ? '' : 's'} para finalizar a lista.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onEditNote,
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(list.note == null || list.note!.isEmpty
                  ? 'Adicionar observações'
                  : 'Editar observações'),
            ),
            if (list.note != null && list.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: (surfaces?.surface ?? colorScheme.surfaceVariant)
                      .withOpacity(0.6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    list.note!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}

class _ViewModeSelector extends StatelessWidget {
  const _ViewModeSelector({required this.controller, required this.theme});

  final ShoppingListDetailController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SegmentedButton<ShoppingListViewMode>(
        segments: const <ButtonSegment<ShoppingListViewMode>>[
          ButtonSegment(
            value: ShoppingListViewMode.recipe,
            label: Text('Por receita'),
            icon: Icon(Icons.menu_book_outlined),
          ),
          ButtonSegment(
            value: ShoppingListViewMode.market,
            label: Text('Por mercado'),
            icon: Icon(Icons.store_mall_directory_outlined),
          ),
        ],
        selected: <ShoppingListViewMode>{controller.viewMode.value},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            controller.toggleViewMode(selection.first);
          }
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return theme.colorScheme.primary.withOpacity(0.15);
            }
            return theme.colorScheme.surfaceVariant.withOpacity(0.4);
          }),
        ),
      );
    });
  }
}

class _RecipeView extends StatelessWidget {
  const _RecipeView({
    required this.controller,
    required this.theme,
    required this.surfaces,
    required this.list,
  });

  final ShoppingListDetailController controller;
  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final ShoppingList list;

  @override
  Widget build(BuildContext context) {
    if (list.sections.isEmpty) {
      return _EmptyState(
        theme: theme,
        message: 'Nenhum item foi salvo nesta lista ainda.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: list.sections.map((section) {
        final pending = section.totalItems - section.completedItems;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.toggleSection(
                          sectionId: section.id,
                          markCompleted: pending > 0,
                        ),
                        icon: Icon(
                          pending > 0
                              ? Icons.checklist_outlined
                              : Icons.restart_alt,
                        ),
                        label: Text(
                          pending > 0 ? 'Marcar tudo' : 'Limpar marcações',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...section.items.map(
                    (item) => CheckboxListTile(
                      value: item.completed,
                      onChanged: (_) => controller.toggleItem(
                        sectionId: section.id,
                        itemId: item.id,
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item.label),
                      subtitle: item.recipeName.isNotEmpty
                          ? Text(
                              item.recipeName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.65),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MarketView extends StatelessWidget {
  const _MarketView({
    required this.controller,
    required this.theme,
    required this.surfaces,
    required this.sections,
  });

  final ShoppingListDetailController controller;
  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final List<AggregatedShoppingSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return _EmptyState(
        theme: theme,
        message: 'Não encontramos itens para agrupar no momento.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.toggleAggregatedSection(section),
                        icon: Icon(
                          section.isCompleted
                              ? Icons.restart_alt
                              : Icons.task_alt_outlined,
                        ),
                        label: Text(
                          section.isCompleted ? 'Limpar marcações' : 'Marcar tudo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...section.items.map(
                    (item) => CheckboxListTile(
                      value: item.completed,
                      onChanged: (_) => controller.toggleAggregatedItem(item),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item.label),
                      subtitle: Text(
                        item.recipeSummary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.message});

  final ThemeData theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _ListOptionsMenu extends StatelessWidget {
  const _ListOptionsMenu({required this.controller});

  final ShoppingListDetailController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleSelection(context, value),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _MenuAction.rename,
          child: Text('Renomear lista'),
        ),
        PopupMenuItem(
          value: _MenuAction.addNote,
          child: Text('Adicionar observações'),
        ),
        PopupMenuItem(
          value: _MenuAction.markAll,
          child: Text('Marcar todos como concluídos'),
        ),
        PopupMenuItem(
          value: _MenuAction.clearMarks,
          child: Text('Limpar marcações'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.remove,
          child: Text('Remover lista'),
        ),
      ],
    );
  }

  Future<void> _handleSelection(
    BuildContext context,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.rename:
        await _showRenameDialog(context);
        break;
      case _MenuAction.addNote:
        await _showNoteDialog(context);
        break;
      case _MenuAction.markAll:
        await controller.toggleAll(markCompleted: true);
        break;
      case _MenuAction.clearMarks:
        await controller.toggleAll(markCompleted: false);
        break;
      case _MenuAction.remove:
        final confirmed = await _showRemovalDialog(context);
        if (confirmed == true) {
          await controller.removeList();
        }
        break;
    }
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final list = controller.list.value;
    if (list == null) {
      return;
    }
    final textController = TextEditingController(text: list.title);
    final result = await Get.dialog<String?>(
      AlertDialog(
        title: const Text('Renomear lista'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Ex.: Compras da semana',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: textController.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await controller.renameList(result);
    }
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    final page = context.findAncestorWidgetOfExactType<ShoppingListDetailPage>();
    if (page != null) {
      await page._showNoteDialog(context);
    }
  }

  Future<bool?> _showRemovalDialog(BuildContext context) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remover esta lista?'),
        content: const Text(
          'Essa ação vai apagar todos os itens desta lista de compras. Você poderá gerar outra a partir do histórico quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { rename, addNote, markAll, clearMarks, remove }
