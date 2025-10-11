import 'package:flutter/material.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';

class EmptyRecipesView extends StatelessWidget {
  const EmptyRecipesView({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.35),
                    (surfaces?.surface ?? theme.colorScheme.surface)
                        .withOpacity(0.9),
                  ],
                ),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 28,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
