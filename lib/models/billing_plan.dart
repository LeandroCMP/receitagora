import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class BillingPlan extends Equatable {
  const BillingPlan({
    required this.id,
    required this.priceId,
    required this.name,
    required this.interval,
    required this.amount,
    required this.currency,
    this.description,
    this.highlighted = false,
  });

  final String id;
  final String priceId;
  final String name;
  final String interval;
  final int amount;
  final String currency;
  final String? description;
  final bool highlighted;

  String get formattedPrice {
    final format = NumberFormat.simpleCurrency(
      name: currency.toUpperCase(),
      locale: 'pt_BR',
    );
    return format.format(amount / 100);
  }

  String get intervalLabel {
    switch (interval.toLowerCase()) {
      case 'year':
      case 'annual':
        return 'ano';
      case 'week':
        return 'semana';
      case 'day':
        return 'dia';
      default:
        return 'mês';
    }
  }

  String get displayPrice => '$formattedPrice / $intervalLabel';

  BillingPlan copyWith({
    String? id,
    String? priceId,
    String? name,
    String? interval,
    int? amount,
    String? currency,
    String? description,
    bool? highlighted,
  }) {
    return BillingPlan(
      id: id ?? this.id,
      priceId: priceId ?? this.priceId,
      name: name ?? this.name,
      interval: interval ?? this.interval,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      highlighted: highlighted ?? this.highlighted,
    );
  }

  factory BillingPlan.fromMap(Map<String, dynamic> map) {
    return BillingPlan(
      id: (map['id'] as String?)?.trim() ?? '',
      priceId: (map['priceId'] as String?)?.trim() ?? '',
      name: (map['name'] as String?)?.trim() ?? 'Premium',
      interval: (map['interval'] as String?)?.trim() ?? 'month',
      amount: map['amount'] is num ? (map['amount'] as num).toInt() : 0,
      currency: (map['currency'] as String?)?.trim() ?? 'BRL',
      description: (map['description'] as String?)?.trim(),
      highlighted: map['highlighted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'priceId': priceId,
      'name': name,
      'interval': interval,
      'amount': amount,
      'currency': currency,
      'description': description,
      'highlighted': highlighted,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        priceId,
        name,
        interval,
        amount,
        currency,
        description,
        highlighted,
      ];
}

class BillingPortalSession {
  const BillingPortalSession({
    required this.url,
    this.expiresAt,
  });

  final Uri url;
  final DateTime? expiresAt;

  factory BillingPortalSession.fromMap(Map<String, dynamic> map) {
    final urlString = map['url'] as String?;
    return BillingPortalSession(
      url: Uri.parse(urlString ?? ''),
      expiresAt: _parseDate(map['expiresAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
          .toLocal();
    }
    return null;
  }
}
