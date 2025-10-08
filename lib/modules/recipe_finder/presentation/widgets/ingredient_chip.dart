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
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor: Color.alphaBlend(
        theme.colorScheme.primary.withOpacity(0.12),
        Colors.black.withOpacity(0.18),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      deleteIconColor: Colors.white.withOpacity(0.9),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
    );
  }
}
