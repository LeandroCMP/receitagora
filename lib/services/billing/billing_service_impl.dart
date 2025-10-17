import 'dart:async';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:receitagora/models/subscription_plan.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'billing_service.dart';
import 'plan_service.dart';

class BillingServiceImpl extends GetxService implements BillingService {
  BillingServiceImpl({
    required InAppPurchase iap,
    required FirebaseFunctions functions,
    required PlanService planService,
    required SessionService sessionService,
    BillingProductIdResolver? productIdResolver,
  })  : _iap = iap,
        _functions = functions,
        _planService = planService,
        _sessionService = sessionService,
        _resolveProductId =
            productIdResolver ?? BillingServiceImpl.defaultProductIdResolver,
        _state = const BillingState(isStoreAvailable: false).obs,
        _products = <BillingProduct>[].obs;

  final InAppPurchase _iap;
  final FirebaseFunctions _functions;
  final PlanService _planService;
  final SessionService _sessionService;
  final BillingProductIdResolver _resolveProductId;

  final Rx<BillingState> _state;
  final RxList<BillingProduct> _products;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _initialized = false;

  static String defaultProductIdResolver(BillingProductType type) {
    switch (type) {
      case BillingProductType.premiumMonthly:
        return 'premium_monthly';
      case BillingProductType.premiumAnnual:
        return 'premium_annual';
    }
  }

  @override
  BillingState get state => _state.value;

  @override
  Stream<BillingState> get stateStream => _state.stream;

  @override
  List<BillingProduct> get products => _products.toList(growable: false);

  @override
  Stream<List<BillingProduct>> get productsStream => _products.stream;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _state.value =
        _state.value.copyWith(isLoading: true, clearError: true, purchasePending: false);

    final available = await _iap.isAvailable();
    _state.value =
        _state.value.copyWith(isStoreAvailable: available, isLoading: false);

    if (!available) {
      return;
    }

    try {
      final productIds = BillingProductType.values
          .map(_resolveProductId)
          .where((id) => id.isNotEmpty)
          .toSet();
      if (productIds.isEmpty) {
        _state.value = _state.value.copyWith(
          errorMessage: 'Nenhum produto configurado para assinatura.',
        );
        return;
      }

      final response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        _state.value = _state.value.copyWith(
          errorMessage: response.error?.message ??
              'Não foi possível carregar os produtos de assinatura.',
        );
        return;
      }

      final resolved = response.productDetails.map((details) {
        final type = _mapProductType(details.id);
        return BillingProduct(type: type, details: details);
      }).toList();

      resolved.sort((a, b) => a.details.price.compareTo(b.details.price));
      _products.assignAll(resolved);

      _purchaseSubscription ??=
          _iap.purchaseStream.listen(_onPurchaseUpdated, onError: (Object error) {
        _state.value = _state.value.copyWith(
          errorMessage: 'Falha ao processar a compra: $error',
          purchasePending: false,
          lastPurchaseSucceeded: false,
        );
      });
    } catch (error, stackTrace) {
      log('Erro ao inicializar cobrança: $error\n$stackTrace');
      _state.value = _state.value.copyWith(
        errorMessage: 'Não foi possível iniciar a cobrança agora.',
        purchasePending: false,
        lastPurchaseSucceeded: false,
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  @override
  void onClose() {
    unawaited(dispose());
    super.onClose();
  }

  @override
  Future<void> buyProduct(BillingProductType type) async {
    await _sessionService.ensureInitialized();
    if (!_sessionService.isAuthenticated) {
      throw Exception('Faça login para concluir a assinatura.');
    }

    if (!_initialized) {
      await init();
    }

    if (!_state.value.isStoreAvailable) {
      throw Exception('A loja de assinaturas não está disponível no momento.');
    }

    final productId = _resolveProductId(type);
    final product = _products.firstWhereOrNull((item) => item.details.id == productId);
    if (product == null) {
      throw Exception('Produto de assinatura indisponível.');
    }

    final purchaseParam = PurchaseParam(productDetails: product.details);
    _state.value = _state.value.copyWith(
      purchasePending: true,
      lastPurchaseProduct: type,
      lastPurchaseSucceeded: false,
      clearError: true,
    );

    final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!success) {
      _state.value = _state.value.copyWith(
        purchasePending: false,
        lastPurchaseSucceeded: false,
        errorMessage: 'Não foi possível iniciar a compra.',
      );
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!_initialized) {
      await init();
    }
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _state.value = _state.value.copyWith(purchasePending: true);
          break;
        case PurchaseStatus.error:
          _state.value = _state.value.copyWith(
            purchasePending: false,
            lastPurchaseSucceeded: false,
            errorMessage: purchase.error?.message ??
                'Não foi possível concluir sua compra. Tente novamente.',
          );
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndCompletePurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          _state.value = _state.value.copyWith(
            purchasePending: false,
            lastPurchaseSucceeded: false,
            errorMessage: 'Compra cancelada.',
          );
          break;
      }
    }
  }

  Future<void> _verifyAndCompletePurchase(PurchaseDetails purchase) async {
    try {
      final verified = await _verifyPurchase(purchase);
      if (verified) {
        final type = _mapProductType(purchase.productID);
        _state.value = _state.value.copyWith(
          purchasePending: false,
          lastPurchaseProduct: type,
          lastPurchaseSucceeded: true,
          clearError: true,
        );
      } else {
        _state.value = _state.value.copyWith(
          purchasePending: false,
          lastPurchaseSucceeded: false,
          errorMessage:
              'Não foi possível validar a assinatura. Nenhuma cobrança foi aplicada.',
        );
      }
    } catch (error) {
      _state.value = _state.value.copyWith(
        purchasePending: false,
        lastPurchaseSucceeded: false,
        errorMessage: error.toString(),
      );
    } finally {
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final verificationData = purchase.verificationData.serverVerificationData;
    final source = purchase.verificationData.source;

    final callable = _functions.httpsCallable('billingVerifyPurchase');

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'platform': source == 'app_store' ? 'ios' : 'android',
        'productId': purchase.productID,
        'verificationData': verificationData,
        'transactionId': purchase.purchaseID,
      });

      final data = result.data;
      final success = data['success'] as bool? ?? false;

      if (success) {
        final expiresAt = data['expiresAt'] as String?;
        DateTime? parsedExpiry;
        if (expiresAt != null) {
          parsedExpiry = DateTime.tryParse(expiresAt)?.toUtc();
        }

        if (_sessionService.user != null) {
          final plan = SubscriptionPlan(
            type: SubscriptionPlanType.premium,
            productId: purchase.productID,
            transactionId: purchase.purchaseID,
            expiresAt: parsedExpiry,
            autoRenews: data['autoRenews'] as bool? ?? false,
            platform: data['platform'] as String? ?? source,
          );
          unawaited(
            _planService.upsertPlan(
              userId: _sessionService.user!.id,
              plan: plan,
            ),
          );
        }
      }

      return success;
    } on FirebaseFunctionsException catch (error) {
      throw Exception(
        error.message ??
            'Não foi possível validar a assinatura com o servidor. Tente novamente em instantes.',
      );
    }
  }

  BillingProductType _mapProductType(String productId) {
    for (final type in BillingProductType.values) {
      if (_resolveProductId(type) == productId) {
        return type;
      }
    }
    return BillingProductType.premiumMonthly;
  }
}
