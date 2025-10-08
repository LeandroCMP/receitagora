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
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceVariant.withOpacity(0.45),
                theme.colorScheme.surfaceVariant.withOpacity(0.18),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Sugestão ${position + 1}'.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      recipe.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 18),
                    Text(
                      preview,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.68),
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
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
              const SizedBox(width: 18),
              RecipeCover(
                theme: theme,
                recipe: recipe,
                position: position,
                heroTag: heroTag,
                size: 128,
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
