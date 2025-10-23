import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/models/nutrition/diet_plan.dart';

import 'nutrition_plan_controller.dart';

class NutritionShoppingListPage extends GetView<NutritionPlanController> {
  const NutritionShoppingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
      ),
      body: SafeArea(
        child: Obx(() {
          final plan = controller.currentPlan.value?.plan;
          final items = plan?.shoppingList ?? const <ShoppingListItem>[];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gere um plano nutricional para visualizar a lista de compras detalhada.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final Map<String, List<ShoppingListItem>> grouped = <String, List<ShoppingListItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.category, () => <ShoppingListItem>[]).add(item);
          }

          final categories = grouped.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryItems = grouped[category] ?? const <ShoppingListItem>[];
              return _ShoppingCategorySection(
                category: category,
                items: categoryItems,
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemCount: categories.length,
          );
        }),
      ),
    );
  }
}

class _ShoppingCategorySection extends StatelessWidget {
  const _ShoppingCategorySection({
    required this.category,
    required this.items,
  });

  final String category;
  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _ShoppingItemTile(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  const _ShoppingItemTile({required this.item});

  final ShoppingListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.quantity,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                if (item.alternatives.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Alternativas do laboratório:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...item.alternatives.map(
                    (alternative) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              alternative,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (item.substitutionNote != null && item.substitutionNote!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.substitutionNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
