import 'package:flutter/material.dart';

import '../../domain/entities/recipe_entity.dart';
import 'recipe_cover.dart';

class RecipeSummaryCard extends StatelessWidget {
  const RecipeSummaryCard({
    required this.recipe,
    required this.position,
    required this.heroTag,
    required this.onTap,
    super.key,
  });

  final RecipeEntity recipe;
  final int position;
  final String heroTag;
  final VoidCallback onTap;

  String _buildPreview() {
    final description = recipe.description.trim();
    if (description.isNotEmpty) {
      return description;
    }

    if (recipe.steps.isNotEmpty) {
      return recipe.steps.first.trim();
    }

    return 'Veja os detalhes para preparar essa receita.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _buildPreview();
    final ingredientCount = recipe.ingredients.length;
    final stepCount = recipe.steps.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetaPill(
                              icon: Icons.auto_awesome,
                              label: recipe.difficulty,
                              accent: theme.colorScheme.primary,
                            ),
                            _MetaPill(
                              icon: Icons.schedule_rounded,
                              label: recipe.duration,
                              accent: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  RecipeCover(
                    theme: theme,
                    recipe: recipe,
                    position: position,
                    heroTag: heroTag,
                    size: 120,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.68),
                  height: 1.55,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetaPill(
                    icon: Icons.restaurant_menu,
                    label: '$ingredientCount ingrediente${ingredientCount == 1 ? '' : 's'}',
                    accent: theme.colorScheme.primary.withOpacity(0.75),
                  ),
                  _MetaPill(
                    icon: Icons.format_list_numbered,
                    label: '$stepCount etapa${stepCount == 1 ? '' : 's'}',
                    accent: theme.colorScheme.primary.withOpacity(0.75),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent.withOpacity(0.95)),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
