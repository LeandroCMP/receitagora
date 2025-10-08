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

    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              highlight.withOpacity(0.92),
              highlight.withOpacity(0.45),
              highlight.withOpacity(0.18),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: highlight.withOpacity(0.3),
              blurRadius: 28,
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
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
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
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Receita ${position + 1}'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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
                color: Colors.black.withOpacity(0.78),
                size: size * 0.38,
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      recipe.duration,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
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
