import 'package:flutter/material.dart';

@immutable
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  const AppSurfaceColors({
    required this.lowest,
    required this.low,
    required this.surface,
    required this.high,
    required this.highest,
  });

  final Color lowest;
  final Color low;
  final Color surface;
  final Color high;
  final Color highest;

  @override
  AppSurfaceColors copyWith({
    Color? lowest,
    Color? low,
    Color? surface,
    Color? high,
    Color? highest,
  }) {
    return AppSurfaceColors(
      lowest: lowest ?? this.lowest,
      low: low ?? this.low,
      surface: surface ?? this.surface,
      high: high ?? this.high,
      highest: highest ?? this.highest,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) {
      return this;
    }

    return AppSurfaceColors(
      lowest: Color.lerp(lowest, other.lowest, t) ?? lowest,
      low: Color.lerp(low, other.low, t) ?? low,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      high: Color.lerp(high, other.high, t) ?? high,
      highest: Color.lerp(highest, other.highest, t) ?? highest,
    );
  }
}
