import 'package:flutter/material.dart';

/// Values returned by [AppPageLayout.resolve] to keep content consistently
/// aligned across the application.
class AppPageLayoutValues {
  const AppPageLayoutValues({
    required this.padding,
    required this.maxContentWidth,
  });

  /// Padding applied to the scroll view that wraps each page section.
  final EdgeInsets padding;

  /// Maximum width for the inner content so large screens keep the same
  /// readable column.
  final double maxContentWidth;
}

/// Utility responsible for resolving padding and width constraints based on
/// the available viewport size. This allows every screen to share the same
/// horizontal rhythm and spacing without duplicating breakpoints.
class AppPageLayout {
  const AppPageLayout._();

  /// Calculates the recommended padding and max width for a page.
  static AppPageLayoutValues resolve(
    BoxConstraints constraints, {
    double maxWidth = 760,
    double compactGutter = 20,
    double mediumGutter = 32,
    double expandedGutter = 48,
    double topPadding = 32,
    double bottomPadding = 40,
  }) {
    final width = constraints.maxWidth;
    final horizontalPadding = width < 420
        ? compactGutter
        : width < 720
            ? mediumGutter
            : expandedGutter;

    final resolvedMaxWidth = width < maxWidth ? width : maxWidth;

    return AppPageLayoutValues(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      maxContentWidth: resolvedMaxWidth,
    );
  }
}
