import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/recipe_entity.dart';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: args.heroTag,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.alphaBlend(
                        theme.colorScheme.primary.withOpacity(0.18),
                        theme.colorScheme.surface,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${args.position + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description.isNotEmpty
                            ? description
                            : 'Explore os ingredientes e o modo de preparo para seguir com a receita.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OverviewPill(
                  icon: Icons.restaurant_menu,
                  label: '${recipe.ingredients.length} ingrediente${recipe.ingredients.length == 1 ? '' : 's'}',
                ),
                _OverviewPill(
                  icon: Icons.timer_outlined,
                  label: '${recipe.steps.length} etapa${recipe.steps.length == 1 ? '' : 's'}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withOpacity(0.12),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.74),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredientes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: recipe.ingredients
                  .map(
                    (ingredient) => Chip(
                      label: Text(ingredient),
                      labelStyle: theme.textTheme.bodyMedium,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modo de preparo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              recipe.steps.length,
              (index) {
                final step = recipe.steps[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        alignment: Alignment.topLeft,
                        child: Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
