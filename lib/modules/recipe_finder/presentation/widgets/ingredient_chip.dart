import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

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
    final surfaces = theme.extension<AppSurfaceColors>();
    return Chip(
      label: Text(label),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      backgroundColor:
          (surfaces?.high ?? theme.colorScheme.surfaceVariant).withOpacity(0.35),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      deleteIconColor: theme.colorScheme.onSurface.withOpacity(0.7),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color:
              (surfaces?.high ?? theme.colorScheme.surfaceVariant).withOpacity(0.45),
        ),
      ),
    );
  }
}
