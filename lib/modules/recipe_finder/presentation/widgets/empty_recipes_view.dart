import 'package:flutter/material.dart';

class EmptyRecipesView extends StatelessWidget {
  const EmptyRecipesView({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
