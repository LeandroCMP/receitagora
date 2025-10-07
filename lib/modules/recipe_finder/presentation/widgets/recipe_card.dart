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
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeCover(
                theme: theme,
                recipe: recipe,
                position: position,
                heroTag: heroTag,
              ),
              const SizedBox(height: 22),
              Text(
                preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.72),
                  height: 1.5,
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
                    icon: Icons.auto_awesome,
                    label: recipe.difficulty,
                  ),
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: recipe.duration,
                  ),
                  _MetaPill(
                    icon: Icons.restaurant_menu,
                    label: '$ingredientCount ingrediente${ingredientCount == 1 ? '' : 's'}',
                  ),
                  _MetaPill(
                    icon: Icons.format_list_numbered,
                    label: '$stepCount etapa${stepCount == 1 ? '' : 's'}',
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
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withOpacity(0.12),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(16),
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
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
