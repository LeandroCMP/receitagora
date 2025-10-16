import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/recipe_finder/widgets/recipe_cover.dart';
import 'package:receitagora/services/recipe/favorites_analytics.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'favorited_recipe_entity.dart';
import 'favorites_controller.dart';

class FavoritesPage extends GetView<FavoritesController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final sessionService = Get.find<SessionService>();
    final favoritesService = Get.find<RecipeFavoritesService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          TextButton(
            onPressed: () => Get.offAllNamed(AppRoutes.recipeFinder),
            child: const Text('Buscar receitas'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.05),
                surfaces?.lowest ?? background,
              ),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 760,
                topPadding: 32,
                bottomPadding: 24,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: Obx(() {
                  if (!sessionService.isAuthenticated) {
                    return _GuestNotice(theme: theme, controller: controller);
                  }

                  return StreamBuilder<List<FavoritedRecipeEntity>>(
                    stream: favoritesService.favoritesStream,
                    initialData: favoritesService.favorites,
                    builder: (context, snapshot) {
                      final favorites =
                          snapshot.data ?? const <FavoritedRecipeEntity>[];
                      if (favorites.isEmpty) {
                        return _EmptyFavorites(theme: theme, layout: layout);
                      }

                      final analytics =
                          FavoritesAnalytics.fromFavorites(favorites);
                      final tagStats = analytics.sortedTagEntries
                          .map((entry) => _TagStat(entry.key, entry.value))
                          .toList();

                      return Obx(() {
                        final filteredFavorites =
                            controller.applyTagFilter(favorites);
                        final selectedTag = controller.selectedTag.value;

                        return SingleChildScrollView(
                          padding: layout.padding,
                          physics: const BouncingScrollPhysics(),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: layout.maxContentWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _FavoritesHeader(
                                    theme: theme,
                                    analytics: analytics,
                                    activeTag: selectedTag,
                                  ),
                                  const SizedBox(height: 16),
                                  _FavoritesMetricsGrid(
                                    theme: theme,
                                    analytics: analytics,
                                  ),
                                  if (tagStats.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _TagFilterSection(
                                      theme: theme,
                                      controller: controller,
                                      stats: tagStats,
                                      selectedTag: selectedTag,
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  if (filteredFavorites.isEmpty)
                                    _EmptyFilteredFavorites(
                                      theme: theme,
                                      selectedTag: selectedTag,
                                      onClearFilter: controller.clearTagFilter,
                                    )
                                  else
                                    ...List.generate(
                                      filteredFavorites.length,
                                      (index) {
                                        final favorite = filteredFavorites[index];
                                        return _FavoriteRecipeCard(
                                          controller: controller,
                                          favorite: favorite,
                                          index: index,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                    },
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

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.theme,
    required this.analytics,
    this.activeTag,
  });

  final ThemeData theme;
  final FavoritesAnalytics analytics;
  final String? activeTag;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.85),
            theme.colorScheme.secondaryContainer.withOpacity(0.55),
          ],
        ),
        border: Border.all(
          color:
              (surfaces?.high ?? theme.colorScheme.surfaceVariant).withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.18),
                  ),
                  child: Icon(
                    Icons.bookmarks_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua vitrine pessoal',
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 0.2,
                          color:
                              theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        analytics.totalFavorites == 1
                            ? '1 receita guardada para revisitar quando quiser.'
                            : '${analytics.totalFavorites} receitas prontas para inspirar o próximo prato.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activeTag != null) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: Text(
                      'Filtro ativo: $activeTag',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    backgroundColor:
                        theme.colorScheme.surface.withOpacity(0.18),
                  ),
                  Chip(
                    label: Text(
                      '${analytics.countForTag(activeTag!)} receita${analytics.countForTag(activeTag!) == 1 ? '' : 's'} na categoria',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                      ),
                    ),
                    backgroundColor:
                        theme.colorScheme.surface.withOpacity(0.14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.72),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remova com cuidado: ao confirmar, a receita sai da lista instantaneamente.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.78),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
    required this.controller,
    required this.favorite,
    required this.index,
  });

  final FavoritesController controller;
  final FavoritedRecipeEntity favorite;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = favorite.recipe;
    final equality = const ListEquality<String>();
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    Future<void> editTags() async {
      final updatedTags = await Get.dialog<List<String>>(
        _FavoriteTagEditorDialog(initialTags: favorite.tags),
        barrierDismissible: false,
      );

      if (updatedTags == null) {
        return;
      }

      if (equality.equals(updatedTags, favorite.tags)) {
        AppSnackbar.info(
          title: 'Sem mudanças',
          message: 'As tags permaneceram as mesmas.',
        );
        return;
      }

      await controller.applyTags(favorite, updatedTags);
    }

    String previewText() {
      final description = recipe.description.trim();
      if (description.isNotEmpty) {
        return description;
      }

      if (recipe.steps.isNotEmpty) {
        return recipe.steps.first.trim();
      }

      return 'Toque para visualizar o passo a passo completo desta receita.';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final padding = EdgeInsets.all(isCompact ? 22 : 28);
        final gap = isCompact ? 18.0 : 24.0;

        final cover = RecipeCover(
          theme: theme,
          recipe: recipe,
          position: index,
          heroTag: 'favorite-${favorite.id}',
          size: isCompact ? 116 : 136,
          showLabel: false,
        );

        final meta = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              icon: Icons.auto_awesome,
              label: recipe.difficulty,
              color: theme.colorScheme.primary,
            ),
            _InfoChip(
              icon: Icons.schedule_rounded,
              label: recipe.duration,
              color: theme.colorScheme.secondary,
            ),
            _InfoChip(
              icon: Icons.restaurant_menu,
              label:
                  '${recipe.ingredients.length} ingrediente${recipe.ingredients.length == 1 ? '' : 's'}',
              color: theme.colorScheme.tertiary,
            ),
          ],
        );

        final tagsSection = _FavoriteTagsFooter(
          theme: theme,
          tags: favorite.tags,
          onEdit: editTags,
        );

        final removeButton = Tooltip(
          message: 'Remover dos favoritos',
          child: IconButton(
            icon: Icon(
              Icons.favorite,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => controller.confirmRemoval(favorite),
          ),
        );

        final header = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorito ${index + 1}'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            removeButton,
          ],
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 16),
            meta,
            const SizedBox(height: 18),
            Text(
              previewText(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.74),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Toque para abrir ingredientes e modo de preparo completo.',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 18),
            tagsSection,
          ],
        );

        final child = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  SizedBox(height: gap),
                  Align(
                    alignment: Alignment.center,
                    child: cover,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  SizedBox(width: gap),
                  cover,
                ],
              );

        return Card(
          margin: EdgeInsets.only(bottom: isCompact ? 20 : 28),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => controller.openFavorite(favorite, index),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    (surfaces?.highest ?? theme.colorScheme.background),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTagsFooter extends StatelessWidget {
  const _FavoriteTagsFooter({
    required this.theme,
    required this.tags,
    required this.onEdit,
  });

  final ThemeData theme;
  final List<String> tags;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final infoStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      height: 1.5,
    );

    final chips = tags
        .map(
          (tag) => InputChip(
            label: Text(tag),
            avatar: const Icon(Icons.tag, size: 16),
            onPressed: onEdit,
            backgroundColor:
                theme.colorScheme.secondaryContainer.withOpacity(0.4),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isEmpty)
          Text(
            'Organize este favorito com categorias rápidas para encontrá-lo em segundos.',
            style: infoStyle,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              ...chips,
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Gerenciar tags'),
                onPressed: onEdit,
              ),
            ],
          ),
        if (tags.isEmpty) ...[
          const SizedBox(height: 12),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar tags'),
            onPressed: onEdit,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Você pode cadastrar até ${RecipeFavoritesService.maxTagsPerRecipe} tags por receita.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _FavoriteTagEditorDialog extends StatefulWidget {
  const _FavoriteTagEditorDialog({required this.initialTags});

  final List<String> initialTags;

  @override
  State<_FavoriteTagEditorDialog> createState() => _FavoriteTagEditorDialogState();
}

class _FavoriteTagEditorDialogState extends State<_FavoriteTagEditorDialog> {
  late List<String> tags;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    tags = List<String>.from(widget.initialTags)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _limitReached =>
      tags.length >= RecipeFavoritesService.maxTagsPerRecipe;

  void _addTag() {
    final normalized = _normalize(_controller.text);
    if (normalized == null) {
      return;
    }
    if (tags.contains(normalized)) {
      _controller.clear();
      return;
    }
    if (_limitReached) {
      AppSnackbar.info(
        title: 'Limite de tags',
        message:
            'Use no máximo ${RecipeFavoritesService.maxTagsPerRecipe} tags por receita.',
      );
      return;
    }
    setState(() {
      tags = <String>[...tags, normalized]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
    _controller.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      tags = List<String>.from(tags)..remove(tag);
    });
  }

  String? _normalize(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      return null;
    }
    final lower = sanitized.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Organizar tags da receita'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tags.isEmpty)
              Text(
                'Adicione palavras-chave para facilitar buscas futuras.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => InputChip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nova tag',
                hintText: 'Ex.: Café da manhã',
                helperText:
                    'Pressione Enter para adicionar. Limite de ${RecipeFavoritesService.maxTagsPerRecipe} itens.',
              ),
              onSubmitted: (_) => _addTag(),
              enabled: !_limitReached,
            ),
            if (_limitReached)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Limite atingido. Remova uma tag antes de adicionar outra.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<List<String>?>(result: null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Get.back<List<String>>(result: tags),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _FavoritesMetricsGrid extends StatelessWidget {
  const _FavoritesMetricsGrid({
    required this.theme,
    required this.analytics,
  });

  final ThemeData theme;
  final FavoritesAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final items = <_MetricTileData>[
      _MetricTileData(
        icon: Icons.favorite_rounded,
        label: 'Total salvos',
        value: analytics.totalFavorites.toString(),
      ),
      _MetricTileData(
        icon: Icons.local_dining_outlined,
        label: 'Ingredientes únicos',
        value: analytics.uniqueIngredients.toString(),
      ),
      _MetricTileData(
        icon: Icons.sell_outlined,
        label: 'Tags únicas',
        value: analytics.uniqueTags.toString(),
      ),
      _MetricTileData(
        icon: Icons.auto_awesome,
        label: 'Dificuldade frequente',
        value: analytics.topDifficulty ?? '—',
      ),
      _MetricTileData(
        icon: Icons.history_rounded,
        label: 'Último favorito',
        value: analytics.formattedLastFavorited ?? '—',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final tileWidth = isCompact
            ? constraints.maxWidth
            : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items
              .map(
                (item) => SizedBox(
                  width: isCompact ? constraints.maxWidth : tileWidth,
                  child: _MetricTile(theme: theme, data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTileData {
  const _MetricTileData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.theme,
    required this.data,
  });

  final ThemeData theme;
  final _MetricTileData data;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: (surfaces?.high ?? theme.colorScheme.surface).withOpacity(0.92),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.12),
              ),
              alignment: Alignment.center,
              child: Icon(
                data.icon,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFilterSection extends StatelessWidget {
  const _TagFilterSection({
    required this.theme,
    required this.controller,
    required this.stats,
    required this.selectedTag,
  });

  final ThemeData theme;
  final FavoritesController controller;
  final List<_TagStat> stats;
  final String? selectedTag;

  @override
  Widget build(BuildContext context) {
    final displayStats = stats.take(12).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Categorias salvas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione uma tag para filtrar rapidamente as receitas que compartilham a mesma categoria.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: displayStats
                  .map(
                    (stat) => ChoiceChip(
                      label: Text('${stat.tag} (${stat.count})'),
                      selected: selectedTag == stat.tag,
                      onSelected: (_) => controller.toggleTagFilter(stat.tag),
                    ),
                  )
                  .toList(),
            ),
            if (selectedTag != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.clearTagFilter,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar filtro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyFilteredFavorites extends StatelessWidget {
  const _EmptyFilteredFavorites({
    required this.theme,
    required this.selectedTag,
    required this.onClearFilter,
  });

  final ThemeData theme;
  final String? selectedTag;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nenhuma receita encontrada',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedTag == null
                  ? 'Nenhuma receita corresponde ao filtro aplicado.'
                  : 'Não encontramos receitas com a tag "$selectedTag". Experimente limpar o filtro ou adicionar a tag a outras receitas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.refresh),
                label: const Text('Ver todas as receitas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagStat {
  const _TagStat(this.tag, this.count);

  final String tag;
  final int count;
}


class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.theme,
    required this.layout,
  });

  final ThemeData theme;
  final AppPageLayoutValues layout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: layout.padding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 32, 26, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma receita favorita por aqui',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Busque receitas e toque no ícone de coração para salvar suas preferidas. '
                    'Elas aparecerão aqui para você acessar mais tarde.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => Get.offAllNamed(AppRoutes.recipeFinder),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Descobrir receitas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice({
    required this.theme,
    required this.controller,
  });

  final ThemeData theme;
  final FavoritesController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entre para salvar favoritos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'As receitas favoritas ficam vinculadas à sua conta. Faça login para visualizar ou gerenciar sua lista.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: controller.openFavoritesOnLoginRequirement,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Fazer login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
