import 'package:meta/meta.dart';

@immutable
class UsageConfig {
  const UsageConfig({
    required this.guestMonthlyLimit,
    required this.guestRecipeLimit,
    required this.authenticatedMonthlyLimit,
    required this.shareMonthlyLimit,
    required this.premiumMonthlyLimit,
    required this.premiumShareMonthlyLimit,
  });

  final int guestMonthlyLimit;
  final int guestRecipeLimit;
  final int authenticatedMonthlyLimit;
  final int shareMonthlyLimit;
  final int premiumMonthlyLimit;
  final int premiumShareMonthlyLimit;

  static const UsageConfig defaults = UsageConfig(
    guestMonthlyLimit: 10,
    guestRecipeLimit: 2,
    authenticatedMonthlyLimit: 30,
    shareMonthlyLimit: 10,
    premiumMonthlyLimit: 999,
    premiumShareMonthlyLimit: 999,
  );

  UsageConfig copyWith({
    int? guestMonthlyLimit,
    int? guestRecipeLimit,
    int? authenticatedMonthlyLimit,
    int? shareMonthlyLimit,
    int? premiumMonthlyLimit,
    int? premiumShareMonthlyLimit,
  }) {
    return UsageConfig(
      guestMonthlyLimit: guestMonthlyLimit ?? this.guestMonthlyLimit,
      guestRecipeLimit: guestRecipeLimit ?? this.guestRecipeLimit,
      authenticatedMonthlyLimit:
          authenticatedMonthlyLimit ?? this.authenticatedMonthlyLimit,
      shareMonthlyLimit: shareMonthlyLimit ?? this.shareMonthlyLimit,
      premiumMonthlyLimit: premiumMonthlyLimit ?? this.premiumMonthlyLimit,
      premiumShareMonthlyLimit:
          premiumShareMonthlyLimit ?? this.premiumShareMonthlyLimit,
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
      guestMonthlyLimit: _readLimit('guestMonthlyLimit', fallback.guestMonthlyLimit)
          .clamp(0, 999),
      guestRecipeLimit:
          _readLimit('guestRecipeLimit', fallback.guestRecipeLimit).clamp(0, 999),
      authenticatedMonthlyLimit: _readLimit(
        'authenticatedMonthlyLimit',
        fallback.authenticatedMonthlyLimit,
      ).clamp(0, 999),
      shareMonthlyLimit:
          _readLimit('shareMonthlyLimit', fallback.shareMonthlyLimit).clamp(0, 999),
      premiumMonthlyLimit:
          _readLimit('premiumMonthlyLimit', fallback.premiumMonthlyLimit)
              .clamp(0, 5000),
      premiumShareMonthlyLimit: _readLimit(
        'premiumShareMonthlyLimit',
        fallback.premiumShareMonthlyLimit,
      ).clamp(0, 5000),
    );
  }

  Map<String, dynamic> toSerializableMap() {
    return <String, dynamic>{
      'guestMonthlyLimit': guestMonthlyLimit,
      'guestRecipeLimit': guestRecipeLimit,
      'authenticatedMonthlyLimit': authenticatedMonthlyLimit,
      'shareMonthlyLimit': shareMonthlyLimit,
      'premiumMonthlyLimit': premiumMonthlyLimit,
      'premiumShareMonthlyLimit': premiumShareMonthlyLimit,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UsageConfig &&
        other.guestMonthlyLimit == guestMonthlyLimit &&
        other.guestRecipeLimit == guestRecipeLimit &&
        other.authenticatedMonthlyLimit == authenticatedMonthlyLimit &&
        other.shareMonthlyLimit == shareMonthlyLimit;
  }

  @override
  int get hashCode => Object.hash(
        guestMonthlyLimit,
        guestRecipeLimit,
        authenticatedMonthlyLimit,
        shareMonthlyLimit,
        premiumMonthlyLimit,
        premiumShareMonthlyLimit,
      );
}
