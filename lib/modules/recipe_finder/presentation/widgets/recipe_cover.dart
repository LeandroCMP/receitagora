import 'package:flutter/material.dart';

import '../../domain/entities/recipe_entity.dart';

class RecipeCover extends StatelessWidget {
  const RecipeCover({
    required this.theme,
    required this.recipe,
    required this.position,
    required this.heroTag,
    this.height = 168,
  });

  final ThemeData theme;
  final RecipeEntity recipe;
  final int position;
  final String heroTag;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(0.95),
        theme.colorScheme.secondary.withOpacity(0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Hero(
            tag: heroTag,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: gradient,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Receita ${position + 1}'.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.9), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        recipe.duration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
