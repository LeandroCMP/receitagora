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
      deleteIcon: const Icon(Icons.close, size: 18),
      backgroundColor: Color.alphaBlend(
        theme.colorScheme.primary.withOpacity(0.18),
        theme.colorScheme.surface,
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      deleteIconColor: theme.colorScheme.onSurface.withOpacity(0.55),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.35)),
      ),
    );
  }
}
