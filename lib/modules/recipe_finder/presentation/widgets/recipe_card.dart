import 'package:flutter/material.dart';

import '../../domain/entities/recipe_entity.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    required this.recipe,
    required this.position,
    super.key,
  });

  final RecipeEntity recipe;
  final int position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.surface,
                    ),
                  ),
                  child: Text(
                    '${position + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 6),
                      Text(
                        recipe.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Ingredientes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipe.ingredients
                  .map(
                    (ingredient) => Chip(
                      label: Text(ingredient),
                      backgroundColor: Color.alphaBlend(
                        theme.colorScheme.primary.withOpacity(0.12),
                        theme.colorScheme.surface,
                      ),
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Modo de preparo',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...recipe.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium,
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
