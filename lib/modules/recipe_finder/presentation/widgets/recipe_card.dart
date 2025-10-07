import 'package:flutter/material.dart';

import '../../domain/entities/recipe_entity.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: heroTag,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.alphaBlend(
                          theme.colorScheme.primary.withOpacity(0.16),
                          theme.colorScheme.surface,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${position + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preview,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.68),
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetaPill(
                    icon: Icons.restaurant_menu,
                    label: '$ingredientCount ingrediente${ingredientCount == 1 ? '' : 's'}',
                  ),
                  _MetaPill(
                    icon: Icons.timer_outlined,
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
