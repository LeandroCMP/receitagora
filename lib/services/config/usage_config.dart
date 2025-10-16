import 'package:meta/meta.dart';

@immutable
class UsageConfig {
  const UsageConfig({
    required this.guestDailyLimit,
    required this.guestRecipeLimit,
    required this.shareDailyLimit,
  });

  final int guestDailyLimit;
  final int guestRecipeLimit;
  final int shareDailyLimit;

  static const UsageConfig defaults = UsageConfig(
    guestDailyLimit: 2,
    guestRecipeLimit: 2,
    shareDailyLimit: 50,
  );

  UsageConfig copyWith({
    int? guestDailyLimit,
    int? guestRecipeLimit,
    int? shareDailyLimit,
  }) {
    return UsageConfig(
      guestDailyLimit: guestDailyLimit ?? this.guestDailyLimit,
      guestRecipeLimit: guestRecipeLimit ?? this.guestRecipeLimit,
      shareDailyLimit: shareDailyLimit ?? this.shareDailyLimit,
    );
  }

  factory UsageConfig.fromMap(Map<String, dynamic> map, UsageConfig fallback) {
    int _readLimit(String key, int current) {
      final value = map[key];
      if (value is int) {
        return value.clamp(0, 999) as int;
      }
      if (value is num) {
        return value.toInt().clamp(0, 999);
      }
      return current;
    }

    return UsageConfig(
      guestDailyLimit:
          _readLimit('guestDailyLimit', fallback.guestDailyLimit).clamp(0, 999),
      guestRecipeLimit:
          _readLimit('guestRecipeLimit', fallback.guestRecipeLimit).clamp(0, 999),
      shareDailyLimit:
          _readLimit('shareDailyLimit', fallback.shareDailyLimit).clamp(0, 999),
    );
  }

  Map<String, dynamic> toSerializableMap() {
    return <String, dynamic>{
      'guestDailyLimit': guestDailyLimit,
      'guestRecipeLimit': guestRecipeLimit,
      'shareDailyLimit': shareDailyLimit,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UsageConfig &&
        other.guestDailyLimit == guestDailyLimit &&
        other.guestRecipeLimit == guestRecipeLimit &&
        other.shareDailyLimit == shareDailyLimit;
  }

  @override
  int get hashCode => Object.hash(
        guestDailyLimit,
        guestRecipeLimit,
        shareDailyLimit,
      );
}
