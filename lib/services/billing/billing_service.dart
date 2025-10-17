import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

enum BillingProductType { premiumMonthly, premiumAnnual }

typedef BillingProductIdResolver = String Function(BillingProductType type);

class BillingProduct {
  BillingProduct({
    required this.type,
    required this.details,
  });

  final BillingProductType type;
  final ProductDetails details;
}

class BillingState {
  const BillingState({
    required this.isStoreAvailable,
    this.isLoading = false,
    this.purchasePending = false,
    this.errorMessage,
    this.lastPurchaseProduct,
    this.lastPurchaseSucceeded = false,
  });

  final bool isStoreAvailable;
  final bool isLoading;
  final bool purchasePending;
  final String? errorMessage;
  final BillingProductType? lastPurchaseProduct;
  final bool lastPurchaseSucceeded;

  BillingState copyWith({
    bool? isStoreAvailable,
    bool? isLoading,
    bool? purchasePending,
    String? errorMessage,
    bool clearError = false,
    BillingProductType? lastPurchaseProduct,
    bool? lastPurchaseSucceeded,
  }) {
    return BillingState(
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      isLoading: isLoading ?? this.isLoading,
      purchasePending: purchasePending ?? this.purchasePending,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      lastPurchaseProduct: lastPurchaseProduct ?? this.lastPurchaseProduct,
      lastPurchaseSucceeded:
          lastPurchaseSucceeded ?? this.lastPurchaseSucceeded,
    );
  }
}

abstract class BillingService {
  Future<void> init();
  Future<void> dispose();

  BillingState get state;
  Stream<BillingState> get stateStream;

  List<BillingProduct> get products;
  Stream<List<BillingProduct>> get productsStream;

  Future<void> buyProduct(BillingProductType type);
  Future<void> restorePurchases();
}
