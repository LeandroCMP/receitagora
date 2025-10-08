import 'package:flutter/material.dart';

import '../../domain/entities/recipe_entity.dart';

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
    final outline = theme.colorScheme.onPrimary.withOpacity(0.22);

    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              highlight.withOpacity(0.85),
              secondary.withOpacity(0.6),
              highlight.withOpacity(0.35),
              highlight.withOpacity(0.85),
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: highlight.withOpacity(0.25),
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
                    color: theme.colorScheme.onPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Receita ${position + 1}'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
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
                  color: theme.colorScheme.onPrimary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      recipe.duration,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
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
