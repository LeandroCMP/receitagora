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
    final tertiary = theme.colorScheme.tertiary;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final outline =
        (surfaces?.high ?? theme.colorScheme.surfaceVariant).withValues(alpha: 0.45);

    return Hero(
      tag: heroTag,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.2, -0.25),
            radius: 0.85,
            colors: [
              highlight.withValues(alpha: 0.85),
              secondary.withValues(alpha: 0.55),
              tertiary.withValues(alpha: 0.45),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: highlight.withValues(alpha: 0.24),
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
                  border: Border.all(color: outline, width: 1.2),
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.4),
                    radius: 1.05,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: size * 0.58,
                height: size * 0.58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.onPrimary.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.ramen_dining_rounded,
                  color: Colors.white,
                  size: size * 0.34,
                ),
              ),
            ),
            if (showLabel)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: highlight.withValues(alpha: 0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    'Receita ${position + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: highlight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
