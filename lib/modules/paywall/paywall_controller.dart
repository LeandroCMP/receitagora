import 'dart:async';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/services/billing/billing_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class PaywallController extends GetxController {
  PaywallController({
    required this.billingService,
    required this.sessionService,
  }) : state = billingService.state.obs;

  final BillingService billingService;
  final SessionService sessionService;

  final RxList<BillingProduct> products = <BillingProduct>[].obs;
  final Rx<BillingState> state;
  final RxBool isPremium = false.obs;

  final Rxn<BillingProductType> _lastSuccessfulProduct = Rxn();
  String? _lastErrorMessage;

  StreamSubscription<List<BillingProduct>>? _productsSubscription;
  StreamSubscription<BillingState>? _stateSubscription;
  StreamSubscription? _planSubscription;

  @override
  void onInit() {
    super.onInit();
    unawaited(billingService.init());
    products.assignAll(billingService.products);
    state.value = billingService.state;
    isPremium.value = sessionService.isPremium;

    _productsSubscription =
        billingService.productsStream.listen(products.assignAll);
    _stateSubscription = billingService.stateStream.listen(_handleStateUpdate);
    _planSubscription = sessionService.planStream.listen((_) {
      final premium = sessionService.isPremium;
      if (premium && !isPremium.value) {
        AppSnackbar.success(
          title: 'Plano premium ativo',
          message:
              'Obrigado por assinar o ReceitaAgora Premium! Aproveite receitas ilimitadas e compartilhamentos sem restrições.',
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (Get.isDialogOpen == true) {
            return;
          }
          if (Get.currentRoute == AppRoutes.paywall) {
            Get.back<void>();
          }
        });
      }
      isPremium.value = premium;
    });
  }

  bool get isStoreAvailable => state.value.isStoreAvailable;

  bool get isBusy => state.value.isLoading || state.value.purchasePending;

  Future<void> buyProduct(BillingProductType type) async {
    try {
      await billingService.buyProduct(type);
    } catch (error) {
      AppSnackbar.error(
        title: 'Assinatura indisponível',
        message: error.toString(),
      );
    }
  }

  Future<void> restorePurchases() async {
    try {
      await billingService.restorePurchases();
      AppSnackbar.info(
        title: 'Restaurando',
        message: 'Buscando assinaturas anteriores na loja...',
      );
    } catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível restaurar',
        message: error.toString(),
      );
    }
  }

  void _handleStateUpdate(BillingState newState) {
    state.value = newState;
    final error = newState.errorMessage;
    if (error != null && error.isNotEmpty && error != _lastErrorMessage) {
      _lastErrorMessage = error;
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: error,
      );
    }

    if (newState.lastPurchaseSucceeded &&
        newState.lastPurchaseProduct != null &&
        newState.lastPurchaseProduct != _lastSuccessfulProduct.value) {
      _lastSuccessfulProduct.value = newState.lastPurchaseProduct;
      AppSnackbar.success(
        title: 'Assinatura confirmada',
        message:
            'Estamos ativando seu acesso premium. Isso pode levar alguns segundos.',
      );
      unawaited(sessionService.refreshPlan());
    }
  }

  String formatPrice(ProductDetails details) {
    return details.price;
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    _stateSubscription?.cancel();
    _planSubscription?.cancel();
    super.onClose();
  }
}
