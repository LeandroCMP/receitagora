import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double compact = 480;
  static const double medium = 840;
}

class AppResponsive {
  const AppResponsive._();

  static bool isCompact(double width) => width < AppBreakpoints.compact;

  static bool isMedium(double width) =>
      width >= AppBreakpoints.compact && width < AppBreakpoints.medium;

  static bool isExpanded(double width) => width >= AppBreakpoints.medium;

  static T valueForWidth<T>({
    required double width,
    required T compact,
    T? medium,
    T? expanded,
  }) {
    T result;

    if (isExpanded(width) && expanded != null) {
      result = expanded;
    } else if (!isCompact(width) && medium != null) {
      result = medium;
    } else {
      result = compact;
    }

    if (T == double && result is num) {
      return result.toDouble() as T;
    }

    return result;
  }
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;

  bool get isCompactScreen => AppResponsive.isCompact(screenSize.width);

  bool get isMediumScreen => AppResponsive.isMedium(screenSize.width);

  bool get isExpandedScreen => AppResponsive.isExpanded(screenSize.width);

  T responsiveValue<T>({
    required T compact,
    T? medium,
    T? expanded,
  }) {
    return AppResponsive.valueForWidth(
      width: screenSize.width,
      compact: compact,
      medium: medium,
      expanded: expanded,
    );
  }
}
