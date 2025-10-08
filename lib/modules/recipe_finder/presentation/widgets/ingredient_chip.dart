import 'package:flutter/material.dart';

class IngredientChip extends StatelessWidget {
  const IngredientChip({
    required this.label,
    required this.onDeleted,
    super.key,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      deleteIconColor: theme.colorScheme.onSurface.withOpacity(0.7),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.25)),
      ),
    );
  }
}
