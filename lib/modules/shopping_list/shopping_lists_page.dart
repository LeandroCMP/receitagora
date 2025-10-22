import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';

import 'shopping_lists_controller.dart';

class ShoppingListsPage extends GetView<ShoppingListsController> {
  const ShoppingListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de compras'),
        actions: [
          Obx(() {
            final isCreating = controller.isCreating.value;
            return TextButton.icon(
              onPressed: isCreating ? null : controller.promptCreationFromHistory,
              icon: isCreating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(isCreating ? 'Preparando...' : 'Nova lista'),
            );
          }),
          const SizedBox(width: 12),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 760,
                topPadding: 32,
                bottomPadding: 32,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: Obx(() {
                  final lists = controller.lists.toList();
                  if (lists.isEmpty) {
                    return SingleChildScrollView(
                      padding: layout.padding,
                      physics: const BouncingScrollPhysics(),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: layout.maxContentWidth),
                          child: _EmptyShoppingLists(
                            theme: theme,
                            surfaces: surfaces,
                            controller: controller,
                          ),
                        ),
                      ),
                    );
                  }

                  final totalPending = lists.fold<int>(
                    0,
                    (total, list) => total + (list.totalItems - list.completedItems),
                  );
                  final activeLists = lists.where((list) => !list.isCompleted).length;

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
                            _ShoppingListSummary(
                              theme: theme,
                              surfaces: surfaces,
                              totalLists: lists.length,
                              activeLists: activeLists,
                              pendingItems: totalPending,
                            ),
                            const SizedBox(height: 24),
                            ...lists.map(
                              (list) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ShoppingListCard(
                                  theme: theme,
                                  surfaces: surfaces,
                                  list: list,
                                  onTap: () => controller.openList(list),
                                ),
                              ),
                            ),
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
}

class _ShoppingListSummary extends StatelessWidget {
  const _ShoppingListSummary({
    required this.theme,
    required this.surfaces,
    required this.totalLists,
    required this.activeLists,
    required this.pendingItems,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final int totalLists;
  final int activeLists;
  final int pendingItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.88),
            (surfaces?.surface ?? colorScheme.surfaceVariant).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organize suas próximas compras',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalLists == 1
                  ? '1 lista criada com base nas suas últimas buscas.'
                  : '$totalLists listas criadas com base nas suas últimas buscas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryTile(
                  theme: theme,
                  label: 'Listas ativas',
                  value: activeLists.toString(),
                  icon: Icons.checklist_rtl,
                  backgroundColor:
                      colorScheme.secondaryContainer.withOpacity(0.45),
                ),
                _SummaryTile(
                  theme: theme,
                  label: 'Itens pendentes',
                  value: pendingItems.toString(),
                  icon: Icons.pending_actions_outlined,
                  backgroundColor:
                      colorScheme.tertiaryContainer.withOpacity(0.45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingListCard extends StatelessWidget {
  const _ShoppingListCard({
    required this.theme,
    required this.surfaces,
    required this.list,
    required this.onTap,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final ShoppingList list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final progress = list.totalItems == 0
        ? 0.0
        : list.completedItems / list.totalItems;
    final formattedDate = _formatDate(list.updatedAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          colorScheme.primaryContainer.withOpacity(0.35),
                    ),
                    child: Icon(
                      list.isCompleted
                          ? Icons.celebration_outlined
                          : Icons.shopping_cart_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${list.completedItems} de ${list.totalItems} itens concluídos • Atualizada em $formattedDate',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: (surfaces?.surface ??
                          colorScheme.surfaceVariant.withOpacity(0.4))
                      .withOpacity(0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    list.isCompleted
                        ? colorScheme.secondary
                        : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _EmptyShoppingLists extends StatelessWidget {
  const _EmptyShoppingLists({
    required this.theme,
    required this.surfaces,
    required this.controller,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final ShoppingListsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 42, 32, 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (surfaces?.lowest ?? colorScheme.surfaceVariant).withOpacity(0.85),
            colorScheme.background,
          ],
        ),
        border: Border.all(
          color: (surfaces?.high ?? colorScheme.surfaceVariant).withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Crie sua primeira lista inteligente',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aproveite as combinações do histórico para organizar compras por receita e evitar esquecimentos no mercado.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.72),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final isCreating = controller.isCreating.value;
            return FilledButton.icon(
              onPressed: isCreating ? null : controller.promptCreationFromHistory,
              icon: isCreating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.history_toggle_off_outlined),
              label: Text(isCreating ? 'Carregando...' : 'Escolher busca recente'),
            );
          }),
        ],
      ),
    );
  }
}
