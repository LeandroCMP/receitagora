import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';

import 'recipe_history_controller.dart';

class RecipeHistoryPage extends GetView<RecipeHistoryController> {
  const RecipeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de buscas'),
        actions: [
          Obx(() {
            final hasEntries = controller.entries.isNotEmpty;
            final isClearing = controller.isClearing.value;
            return TextButton.icon(
              onPressed:
                  !hasEntries || isClearing ? null : controller.clearHistory,
              icon: isClearing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_outlined),
              label: Text(isClearing ? 'Limpando...' : 'Limpar tudo'),
            );
          }),
          const SizedBox(width: 8),
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
                  final entries = controller.entries.toList();

                  if (entries.isEmpty) {
                    return SingleChildScrollView(
                      padding: layout.padding,
                      physics: const BouncingScrollPhysics(),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: layout.maxContentWidth),
                          child: _EmptyHistory(theme: theme),
                        ),
                      ),
                    );
                  }

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
                            _HistorySummaryCard(theme: theme, entries: entries),
                            const SizedBox(height: 24),
                            ...entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _HistoryEntryCard(
                                  theme: theme,
                                  entry: entry,
                                  controller: controller,
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

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.theme,
    required this.entries,
  });

  final ThemeData theme;
  final List<RecipeHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final total = entries.length;
    final latest = entries.first;
    final formattedDate = _formatDate(latest.timestamp);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.85),
            (surfaces?.surface ?? colorScheme.surfaceVariant)
                .withOpacity(0.9),
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
              total == 1
                  ? '1 combinação salva para revisitar quando quiser.'
                  : '$total combinações salvas para revisitar quando quiser.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A última busca registrada foi em $formattedDate. Abra qualquer item para visualizar as receitas sem precisar gerar novamente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.85),
                height: 1.5,
              ),
            ),
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

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.theme,
    required this.entry,
    required this.controller,
  });

  final ThemeData theme;
  final RecipeHistoryEntry entry;
  final RecipeHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final formattedTimestamp = _formatTimestamp(entry.timestamp);
    final ingredientChips = entry.ingredients.take(6).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondaryContainer.withOpacity(0.35),
                  ),
                  child: Icon(
                    Icons.auto_awesome_mosaic_outlined,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildTitle(entry.ingredients),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$formattedTimestamp • ${entry.totalRecipes} receita${entry.totalRecipes == 1 ? '' : 's'} sugeridas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (ingredientChips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredientChips
                    .map(
                      (ingredient) => Chip(
                        label: Text(ingredient),
                        backgroundColor:
                            colorScheme.surfaceVariant.withOpacity(0.6),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => controller.openEntry(entry),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Ver receitas'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => controller.removeEntry(entry),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ],
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

  String _buildTitle(List<String> ingredients) {
    if (ingredients.isEmpty) {
      return 'Combinação sem ingredientes registrados';
    }
    if (ingredients.length <= 3) {
      return ingredients.join(', ');
    }
    final display = ingredients.take(3).join(', ');
    final remaining = ingredients.length - 3;
    return '$display +$remaining';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.history_toggle_off_rounded,
          size: 56,
          color: colorScheme.primary.withOpacity(0.45),
        ),
        const SizedBox(height: 20),
        Text(
          'Sem buscas recentes ainda',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sempre que você gerar receitas, guardaremos a combinação aqui para que possa revisitar mesmo sem conexão.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
