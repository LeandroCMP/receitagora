import 'package:flutter/material.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

class RecipeCover extends StatelessWidget {
  const RecipeCover({
    required this.theme,
    required this.recipe,
    required this.position,
    required this.heroTag,
    this.size = 130,
    this.showLabel = true,
  });

  final ThemeData theme;
  final RecipeEntity recipe;
  final int position;
  final String heroTag;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final highlight = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final outline =
        (surfaces?.high ?? theme.colorScheme.surfaceVariant).withOpacity(0.4);

    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              highlight.withOpacity(0.8),
              secondary.withOpacity(0.55),
              highlight.withOpacity(0.32),
              highlight.withOpacity(0.8),
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: highlight.withOpacity(0.2),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: outline, width: 1.4),
                ),
              ),
            ),
            if (showLabel)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: outline),
                  ),
                  child: Text(
                    'Receita ${position + 1}'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.ramen_dining,
                color: theme.colorScheme.primaryContainer,
                size: size * 0.38,
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (surfaces?.high ?? theme.colorScheme.surface)
                      .withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      recipe.duration,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
