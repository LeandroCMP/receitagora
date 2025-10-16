import 'package:flutter/material.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

import 'recipe_cover.dart';

class RecipeSummaryCard extends StatelessWidget {
  const RecipeSummaryCard({
    required this.recipe,
    required this.position,
    required this.heroTag,
    required this.onTap,
    this.action,
    this.footer,
    super.key,
  });

  final RecipeEntity recipe;
  final int position;
  final String heroTag;
  final VoidCallback onTap;
  final Widget? action;
  final Widget? footer;

  String _previewText() {
    final description = recipe.description.trim();
    if (description.isNotEmpty) {
      return description;
    }

    if (recipe.steps.isNotEmpty) {
      return recipe.steps.first.trim();
    }

    return 'Toque para visualizar o passo a passo completo desta receita.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewText();
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 540;
        final padding = EdgeInsets.all(isCompact ? 22 : 28);
        final gap = isCompact ? 20.0 : 28.0;

        final cover = RecipeCover(
          theme: theme,
          recipe: recipe,
          position: position,
          heroTag: heroTag,
          size: isCompact ? 120 : 140,
        );

        final meta = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetaPill(
              icon: Icons.auto_awesome,
              label: recipe.difficulty,
              color: theme.colorScheme.primary,
            ),
            _MetaPill(
              icon: Icons.schedule_rounded,
              label: recipe.duration,
              color: theme.colorScheme.secondary,
            ),
            _MetaPill(
              icon: Icons.restaurant_menu,
              label: '${recipe.ingredients.length} ingrediente${recipe.ingredients.length == 1 ? '' : 's'}',
              color: theme.colorScheme.primary,
            ),
          ],
        );

        final headerChildren = <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sugestão ${position + 1}'.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recipe.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ];

        if (action != null) {
          headerChildren.add(
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: action!,
            ),
          );
        }

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: headerChildren,
            ),
            const SizedBox(height: 14),
            meta,
            const SizedBox(height: 18),
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Toque para ver ingredientes e preparo completo',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 20),
              footer!,
            ],
          ],
        );

        final child = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  SizedBox(height: gap),
                  Align(
                    alignment: Alignment.center,
                    child: cover,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  SizedBox(width: gap),
                  cover,
                ],
              );

        return Card(
          margin: EdgeInsets.only(bottom: isCompact ? 20 : 28),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    (surfaces?.highest ?? theme.colorScheme.background),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
            .withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.78),
              letterSpacing: 0.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
