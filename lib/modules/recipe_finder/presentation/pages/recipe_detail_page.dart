import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/recipe_entity.dart';
import '../widgets/recipe_cover.dart';

const double _compactBreakpoint = 480.0;
const double _mediumBreakpoint = 840.0;

bool _isCompactWidth(double width) => width < _compactBreakpoint;

bool _isExpandedWidth(double width) => width >= _mediumBreakpoint;

T _valueForWidth<T>({
  required double width,
  required T compact,
  T? medium,
  T? expanded,
}) {
  T result;

  if (_isExpandedWidth(width) && expanded != null) {
    result = expanded;
  } else if (!_isCompactWidth(width) && medium != null) {
    result = medium;
  } else {
    result = compact;
  }

  if (T == double && result is num) {
    return result.toDouble() as T;
  }

  return result;
}

class RecipeDetailArgs {
  const RecipeDetailArgs({
    required this.recipe,
    required this.position,
    required this.heroTag,
  });

  final RecipeEntity recipe;
  final int position;
  final String heroTag;
}

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  RecipeDetailArgs _resolveArgs() {
    final dynamic rawArgs = Get.arguments;
    if (rawArgs is RecipeDetailArgs) {
      return rawArgs;
    }

    return RecipeDetailArgs(
      recipe: const RecipeEntity(
        name: 'Receita',
        description: 'Não foi possível carregar os detalhes desta receita.',
        ingredients: [],
        steps: [],
        difficulty: 'Dificuldade desconhecida',
        duration: 'Tempo indisponível',
      ),
      position: 0,
      heroTag: 'recipe-fallback',
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs();
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final overlay = Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.03),
      background,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(args.recipe.name),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [overlay, background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                sliver: SliverToBoxAdapter(
                  child: _OverviewCard(args: args),
                ),
              ),
              if (args.recipe.ingredients.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  sliver: SliverToBoxAdapter(
                    child: _IngredientsCard(recipe: args.recipe),
                  ),
                ),
              if (args.recipe.steps.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: _StepsCard(recipe: args.recipe),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.args});

  final RecipeDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = args.recipe;
    final description = recipe.description.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = _isCompactWidth(width);
          final coverSize = _valueForWidth<double>(
            width: width,
            compact: 128,
            medium: 148,
            expanded: 168,
          );

          final highlight = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Receita ${args.position + 1}'.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                recipe.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _OverviewPill(
                    icon: Icons.auto_awesome,
                    label: recipe.difficulty,
                    accent: Colors.black.withOpacity(0.28),
                  ),
                  _OverviewPill(
                    icon: Icons.schedule_rounded,
                    label: recipe.duration,
                    accent: Colors.black.withOpacity(0.28),
                  ),
                  _OverviewPill(
                    icon: Icons.receipt_long,
                    label: '${recipe.ingredients.length} ingrediente${recipe.ingredients.length == 1 ? '' : 's'}',
                    accent: Colors.black.withOpacity(0.28),
                  ),
                ],
              ),
            ],
          );

          final cover = RecipeCover(
            theme: theme,
            recipe: recipe,
            position: args.position,
            heroTag: args.heroTag,
            size: coverSize,
            showLabel: false,
          );

          final descriptionWidget = Text(
            description.isNotEmpty
                ? description
                : 'Explore os ingredientes e o modo de preparo para seguir com a receita.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.55,
            ),
          );

          final compactLayout = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              highlight,
              const SizedBox(height: 26),
              Align(
                alignment: Alignment.center,
                child: cover,
              ),
              const SizedBox(height: 26),
              descriptionWidget,
            ],
          );

          final expandedLayout = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: highlight),
                  SizedBox(
                    width: _valueForWidth<double>(
                      width: width,
                      compact: 0,
                      medium: 24,
                      expanded: 28,
                    ),
                  ),
                  cover,
                ],
              ),
              const SizedBox(height: 26),
              descriptionWidget,
            ],
          );

          return Container(
            padding: EdgeInsets.fromLTRB(
              _valueForWidth<double>(
                width: width,
                compact: 24,
                medium: 28,
                expanded: 30,
              ),
              _valueForWidth<double>(
                width: width,
                compact: 26,
                medium: 30,
                expanded: 34,
              ),
              _valueForWidth<double>(
                width: width,
                compact: 24,
                medium: 28,
                expanded: 30,
              ),
              _valueForWidth<double>(
                width: width,
                compact: 28,
                medium: 32,
                expanded: 36,
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.68),
                  theme.colorScheme.primary.withOpacity(0.28),
                  theme.colorScheme.primary.withOpacity(0.12),
                ],
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey<bool>(isCompact),
                child: isCompact ? compactLayout : expandedLayout,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.recipe});

  final RecipeEntity recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceVariant.withOpacity(0.35),
              theme.colorScheme.surfaceVariant.withOpacity(0.12),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredientes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: recipe.ingredients
                  .map(
                    (ingredient) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ingredient,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.recipe});

  final RecipeEntity recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
              theme.colorScheme.surfaceVariant.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modo de preparo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              recipe.steps.length,
              (index) {
                final step = recipe.steps[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          step,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
