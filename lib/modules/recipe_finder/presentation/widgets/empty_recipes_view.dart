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
                    theme.colorScheme.primary.withOpacity(0.25),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 28,
                color: theme.colorScheme.onSurface,
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
