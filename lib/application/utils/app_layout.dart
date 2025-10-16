import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Values returned by [AppPageLayout.resolve] to keep content consistently
/// aligned across the application.
class AppPageLayoutValues {
  const AppPageLayoutValues({
    required this.padding,
    required this.maxContentWidth,
    required this.textScaler,
  });

  /// Padding applied to the scroll view that wraps each page section.
  final EdgeInsets padding;

  /// Maximum width for the inner content so large screens keep the same
  /// readable column.
  final double maxContentWidth;

  /// Recommended [TextScaler] to keep large headings responsive to the
  /// available width, preventing overflow on compact devices.
  final TextScaler textScaler;
}

/// Utility responsible for resolving padding and width constraints based on
/// the available viewport size. This allows every screen to share the same
/// horizontal rhythm and spacing without duplicating breakpoints.
class AppPageLayout {
  const AppPageLayout._();

  /// Calculates the recommended padding and max width for a page using
  /// Material Design's compact (phones), medium (small tablets) and expanded
  /// (large tablet/desktop) breakpoints.
  static AppPageLayoutValues resolve(
    BoxConstraints constraints, {
    double maxWidth = 760,
    double compactGutter = 20,
    double mediumGutter = 32,
    double expandedGutter = 48,
    double topPadding = 40,
    double bottomPadding = 48,
  }) {
    final width = constraints.maxWidth;
    final horizontalPadding = width < 600
        ? compactGutter
        : width < 840
            ? mediumGutter
            : expandedGutter;

    final resolvedMaxWidth = math.max(
      0.0,
      math.min(width - (horizontalPadding * 2), maxWidth),
    );

    final textScale = width < 360
        ? 0.9
        : width < 420
            ? 0.94
            : width < 520
                ? 0.98
                : width < 760
                    ? 1.02
                    : width < 1024
                        ? 1.06
                        : 1.1;

    return AppPageLayoutValues(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      maxContentWidth: resolvedMaxWidth,
      textScaler: TextScaler.linear(textScale),
    );
  }
}
