import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum SubscriptionPlanType { visitor, free, premium }

@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.type,
    this.productId,
    this.transactionId,
    this.expiresAt,
    this.autoRenews = false,
    this.platform,
  });

  final SubscriptionPlanType type;
  final String? productId;
  final String? transactionId;
  final DateTime? expiresAt;
  final bool autoRenews;
  final String? platform;

  bool get isPremium => type == SubscriptionPlanType.premium && !isExpired;

  bool get isExpired {
    if (expiresAt == null) {
      return false;
    }
    return expiresAt!.isBefore(DateTime.now().toUtc());
  }

  bool get isActive => type != SubscriptionPlanType.premium || !isExpired;

  factory SubscriptionPlan.visitor() {
    return const SubscriptionPlan(type: SubscriptionPlanType.visitor);
  }

  factory SubscriptionPlan.free() {
    return const SubscriptionPlan(type: SubscriptionPlanType.free);
  }

  SubscriptionPlan copyWith({
    SubscriptionPlanType? type,
    String? productId,
    String? transactionId,
    DateTime? expiresAt,
    bool? autoRenews,
    String? platform,
  }) {
    return SubscriptionPlan(
      type: type ?? this.type,
      productId: productId ?? this.productId,
      transactionId: transactionId ?? this.transactionId,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenews: autoRenews ?? this.autoRenews,
      platform: platform ?? this.platform,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      if (productId != null) 'productId': productId,
      if (transactionId != null) 'transactionId': transactionId,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!.toUtc()),
      'autoRenews': autoRenews,
      if (platform != null) 'platform': platform,
    };
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'];
    final type = SubscriptionPlanType.values.firstWhere(
      (planType) => planType.name == rawType,
      orElse: () => SubscriptionPlanType.free,
    );
    return SubscriptionPlan(
      type: type,
      productId: _readString(map['productId']),
      transactionId: _readString(map['transactionId']),
      expiresAt: _readDate(map['expiresAt']),
      autoRenews: map['autoRenews'] as bool? ?? false,
      platform: _readString(map['platform']),
    );
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

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toUtc();
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SubscriptionPlan) {
      return false;
    }
    return other.type == type &&
        other.productId == productId &&
        other.transactionId == transactionId &&
        other.autoRenews == autoRenews &&
        other.platform == platform &&
        _datesEqual(other.expiresAt, expiresAt);
  }

  @override
  int get hashCode => Object.hash(
        type,
        productId,
        transactionId,
        autoRenews,
        platform,
        expiresAt?.millisecondsSinceEpoch,
      );

  static bool _datesEqual(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.toUtc().millisecondsSinceEpoch == b.toUtc().millisecondsSinceEpoch;
  }
}
