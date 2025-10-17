import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum SubscriptionPlanType { free, premium }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.type,
    this.productId,
    this.priceId,
    this.transactionId,
    this.platform,
    this.autoRenews = false,
    this.expiresAt,
    this.amount,
    this.currency,
    this.interval,
    this.status,
    this.subscriptionId,
    this.cancelAtPeriodEnd = false,
    this.customerId,
    this.updatedAt,
    this.createdAt,
  });

  final SubscriptionPlanType type;
  final String? productId;
  final String? priceId;
  final String? transactionId;
  final String? platform;
  final bool autoRenews;
  final DateTime? expiresAt;
  final int? amount;
  final String? currency;
  final String? interval;
  final String? status;
  final String? subscriptionId;
  final bool cancelAtPeriodEnd;
  final String? customerId;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get isPremium => type == SubscriptionPlanType.premium && !isExpired;

  String get planName => type == SubscriptionPlanType.premium ? 'Premium' : 'Gratuito';

  String? get currencyLabel {
    final value = currency?.toUpperCase();
    return value == null || value.isEmpty ? null : value;
  }

  String? get statusLabel {
    final value = status;
    if (value == null || value.isEmpty) {
      return null;
    }

    switch (value.toLowerCase()) {
      case 'trialing':
        return 'Período de teste';
      case 'active':
        return 'Ativa';
      case 'past_due':
        return 'Pagamento pendente';
      case 'canceled':
        return 'Cancelada';
      case 'incomplete':
        return 'Pagamento incompleto';
      case 'incomplete_expired':
        return 'Pagamento expirado';
      case 'unpaid':
        return 'Pagamento em atraso';
      default:
        return value;
    }
  }

  String? get intervalLabel {
    if (interval == null) {
      return null;
    }
    final normalized = interval!.toLowerCase().trim();
    switch (normalized) {
      case 'day':
        return 'dia';
      case 'week':
        return 'semana';
      case 'year':
      case 'annual':
        return 'ano';
      default:
        return 'mês';
    }
  }

  String? get formattedAmount {
    if (amount == null || amount! <= 0) {
      return null;
    }

    final currencyCode = currencyLabel ?? 'BRL';
    final locale = currencyCode == 'BRL' ? 'pt_BR' : 'en_US';

    return NumberFormat.simpleCurrency(name: currencyCode, locale: locale)
        .format(amount! / 100);
  }

  SubscriptionPlan copyWith({
    SubscriptionPlanType? type,
    String? productId,
    String? priceId,
    String? transactionId,
    String? platform,
    bool? autoRenews,
    DateTime? expiresAt,
    int? amount,
    String? currency,
    String? interval,
    String? status,
    String? subscriptionId,
    bool? cancelAtPeriodEnd,
    String? customerId,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return SubscriptionPlan(
      type: type ?? this.type,
      productId: productId ?? this.productId,
      priceId: priceId ?? this.priceId,
      transactionId: transactionId ?? this.transactionId,
      platform: platform ?? this.platform,
      autoRenews: autoRenews ?? this.autoRenews,
      expiresAt: expiresAt ?? this.expiresAt,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      interval: interval ?? this.interval,
      status: status ?? this.status,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      customerId: customerId ?? this.customerId,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
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
      priceId: _readString(map['priceId']),
      transactionId: _readString(map['transactionId']),
      platform: _readString(map['platform']),
      autoRenews: map['autoRenews'] as bool? ?? false,
      expiresAt: _readExpiration(map['expiresAt']),
      amount: map['amount'] is num ? (map['amount'] as num).toInt() : null,
      currency: _readString(map['currency']),
      interval: _readString(map['interval']),
      status: _readString(map['status']),
      subscriptionId: _readString(map['subscriptionId']),
      cancelAtPeriodEnd: map['cancelAtPeriodEnd'] as bool? ?? false,
      customerId: _readString(map['customerId']),
      updatedAt: _readExpiration(map['updatedAt']),
      createdAt: _readExpiration(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'productId': productId,
      'priceId': priceId,
      'transactionId': transactionId,
      'platform': platform,
      'autoRenews': autoRenews,
      'expiresAt': expiresAt?.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'interval': interval,
      'status': status,
      'subscriptionId': subscriptionId,
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'customerId': customerId,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
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
