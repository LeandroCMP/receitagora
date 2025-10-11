import 'package:flutter/material.dart';

@immutable
class ReceitagoraSurfaceColors
    extends ThemeExtension<ReceitagoraSurfaceColors> {
  const ReceitagoraSurfaceColors({
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
  ReceitagoraSurfaceColors copyWith({
    Color? lowest,
    Color? low,
    Color? surface,
    Color? high,
    Color? highest,
  }) {
    return ReceitagoraSurfaceColors(
      lowest: lowest ?? this.lowest,
      low: low ?? this.low,
      surface: surface ?? this.surface,
      high: high ?? this.high,
      highest: highest ?? this.highest,
    );
  }

  @override
  ReceitagoraSurfaceColors lerp(
    ThemeExtension<ReceitagoraSurfaceColors>? other,
    double t,
  ) {
    if (other is! ReceitagoraSurfaceColors) {
      return this;
    }

    return ReceitagoraSurfaceColors(
      lowest: Color.lerp(lowest, other.lowest, t) ?? lowest,
      low: Color.lerp(low, other.low, t) ?? low,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      high: Color.lerp(high, other.high, t) ?? high,
      highest: Color.lerp(highest, other.highest, t) ?? highest,
    );
  }
}
