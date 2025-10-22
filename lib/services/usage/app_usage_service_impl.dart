import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_usage_service.dart';

class AppUsageServiceImpl extends GetxService implements AppUsageService {
  AppUsageServiceImpl({required SharedPreferences preferences})
      : _preferences = preferences;

  final SharedPreferences _preferences;

  static const String _currentStreakKey = 'usage.currentStreak';
  static const String _longestStreakKey = 'usage.longestStreak';
  static const String _totalOpensKey = 'usage.totalOpens';
  static const String _lastOpenKey = 'usage.lastOpen';

  final Rx<AppUsageMetrics> _metrics =
      const AppUsageMetrics(currentStreak: 0, longestStreak: 0, totalOpens: 0)
          .obs;
  bool _initialized = false;
  Completer<void>? _initializing;

  @override
  AppUsageMetrics get metrics => _metrics.value;

  @override
  Stream<AppUsageMetrics> get metricsStream => _metrics.stream;

  @override
  Future<void> ensureInitialized() async {
    if (_initialized) {
      return _initializing?.future ?? Future<void>.value();
    }

    _initializing ??= Completer<void>();
    if (_initializing!.isCompleted && !_initialized) {
      _initializing = Completer<void>();
    }
    final completer = _initializing!;

    if (completer.isCompleted) {
      return completer.future;
    }

    try {
      final current = _preferences.getInt(_currentStreakKey) ?? 0;
      final longest = _preferences.getInt(_longestStreakKey) ?? 0;
      final total = _preferences.getInt(_totalOpensKey) ?? 0;
      final lastRaw = _preferences.getString(_lastOpenKey);
      final lastDate =
          lastRaw == null ? null : DateTime.tryParse(lastRaw)?.toLocal();
      _metrics.value = AppUsageMetrics(
        currentStreak: current,
        longestStreak: longest,
        totalOpens: total,
        lastOpenDate: lastDate,
      );
      _initialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      _initializing = null;
      rethrow;
    }

    return completer.future;
  }

  @override
  Future<void> registerAppOpen({DateTime? now}) async {
    await ensureInitialized();

    final DateTime reference = now?.toLocal() ?? DateTime.now();
    final DateTime today = DateTime(reference.year, reference.month, reference.day);
    final DateTime? last = _metrics.value.lastOpenDate == null
        ? null
        : DateTime(
            _metrics.value.lastOpenDate!.year,
            _metrics.value.lastOpenDate!.month,
            _metrics.value.lastOpenDate!.day,
          );

    var currentStreak = _metrics.value.currentStreak;
    final longestStreak = _metrics.value.longestStreak;
    var totalOpens = _metrics.value.totalOpens + 1;

    if (last == null) {
      currentStreak = 1;
    } else {
      final difference = today.difference(last).inDays;
      if (difference == 0) {
        // Already counted streak for today; keep value as is.
      } else if (difference == 1) {
        currentStreak += 1;
      } else if (difference > 1) {
        currentStreak = 1;
      }
    }

    final updatedLongest = currentStreak > longestStreak
        ? currentStreak
        : longestStreak;

    final updated = _metrics.value.copyWith(
      currentStreak: currentStreak,
      longestStreak: updatedLongest,
      totalOpens: totalOpens,
      lastOpenDate: today,
    );

    _metrics.value = updated;

    await _preferences.setInt(_currentStreakKey, updated.currentStreak);
    await _preferences.setInt(_longestStreakKey, updated.longestStreak);
    await _preferences.setInt(_totalOpensKey, updated.totalOpens);
    await _preferences.setString(_lastOpenKey, today.toIso8601String());
  }
}
