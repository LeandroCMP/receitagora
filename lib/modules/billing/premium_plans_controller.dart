import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/models/billing_plan.dart';
import 'package:receitagora/services/billing/billing_exception.dart';
import 'package:receitagora/services/billing/billing_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class PremiumPlansController extends GetxController {
  PremiumPlansController({
    required this.billingService,
    required this.sessionService,
  });

  final BillingService billingService;
  final SessionService sessionService;

  final RxList<BillingPlan> plans = <BillingPlan>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _refreshPlans();
  }

  Future<void> _refreshPlans() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      await billingService.ensureInitialized();
      final fetched = await billingService.fetchPlans();
      plans.assignAll(fetched);
    } on BillingException catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível carregar os planos',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message:
            'Não foi possível carregar os planos premium agora. Tente novamente em instantes.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> subscribe(BillingPlan plan) async {
    if (sessionService.hasPremiumAccess) {
      AppSnackbar.info(
        title: 'Você já é premium',
        message: 'Sua assinatura atual já garante todos os benefícios.',
      );
      return;
    }

    if (isProcessing.value) {
      return;
    }

    var overlayShown = false;

    isProcessing.value = true;
    try {
      if (!(Get.isDialogOpen ?? false)) {
        overlayShown = true;
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }

      final result = await billingService.subscribe(plan);
      if (result.completed) {
        if (overlayShown && (Get.isDialogOpen ?? false)) {
          Get.back();
          overlayShown = false;
        }
        await sessionService.refreshSubscriptionPlan();
        AppSnackbar.success(
          title: 'Bem-vindo ao Premium',
          message:
              'Assinatura confirmada com sucesso! Aproveite os benefícios exclusivos imediatamente.',
        );
        Get.back<void>();
      } else if (result.message != null) {
        AppSnackbar.info(
          title: 'Assinatura não concluída',
          message: result.message!,
        );
      }
    } on BillingException catch (error) {
      AppSnackbar.error(
        title: 'Falha na assinatura',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message:
            'Não foi possível concluir a assinatura agora. Tente novamente mais tarde.',
      );
    } finally {
      isProcessing.value = false;
      if (overlayShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }
}
