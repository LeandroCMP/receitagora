import 'dart:async';

class AppUsageMetrics {
  const AppUsageMetrics({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalOpens,
    this.lastOpenDate,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalOpens;
  final DateTime? lastOpenDate;

  AppUsageMetrics copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalOpens,
    DateTime? lastOpenDate,
  }) {
    return AppUsageMetrics(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalOpens: totalOpens ?? this.totalOpens,
      lastOpenDate: lastOpenDate ?? this.lastOpenDate,
    );
  }
}

abstract class AppUsageService {
  Future<void> ensureInitialized();
  Future<void> registerAppOpen({DateTime? now});

  AppUsageMetrics get metrics;
  Stream<AppUsageMetrics> get metricsStream;
}
