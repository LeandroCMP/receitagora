import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlanType { free, premium }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.type,
    this.productId,
    this.transactionId,
    this.platform,
    this.autoRenews = false,
    this.expiresAt,
  });

  final SubscriptionPlanType type;
  final String? productId;
  final String? transactionId;
  final String? platform;
  final bool autoRenews;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isPremium => type == SubscriptionPlanType.premium && !isExpired;

  String get planName => type == SubscriptionPlanType.premium ? 'Premium' : 'Gratuito';

  SubscriptionPlan copyWith({
    SubscriptionPlanType? type,
    String? productId,
    String? transactionId,
    String? platform,
    bool? autoRenews,
    DateTime? expiresAt,
  }) {
    return SubscriptionPlan(
      type: type ?? this.type,
      productId: productId ?? this.productId,
      transactionId: transactionId ?? this.transactionId,
      platform: platform ?? this.platform,
      autoRenews: autoRenews ?? this.autoRenews,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  factory SubscriptionPlan.free() {
    return const SubscriptionPlan(type: SubscriptionPlanType.free);
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    final typeValue = (map['type'] as String?)?.toLowerCase().trim();
    final planType = typeValue == SubscriptionPlanType.premium.name
        ? SubscriptionPlanType.premium
        : SubscriptionPlanType.free;

    return SubscriptionPlan(
      type: planType,
      productId: _readString(map['productId']),
      transactionId: _readString(map['transactionId']),
      platform: _readString(map['platform']),
      autoRenews: map['autoRenews'] as bool? ?? false,
      expiresAt: _readExpiration(map['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'productId': productId,
      'transactionId': transactionId,
      'platform': platform,
      'autoRenews': autoRenews,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SubscriptionPlan.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return SubscriptionPlan.fromMap(decoded);
    }
    throw const FormatException('Invalid subscription plan json');
  }

  static String? _readString(dynamic value) {
    if (value is String) {
      final sanitized = value.trim();
      if (sanitized.isNotEmpty) {
        return sanitized;
      }
    }
    return null;
  }

  static DateTime? _readExpiration(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate().toLocal();
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal();
    }

    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000, isUtc: true)
            .toLocal();
      }
      final isoString = value['isoString'];
      if (isoString is String) {
        return DateTime.tryParse(isoString);
      }
    }

    return null;
  }
}
