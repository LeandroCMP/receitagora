import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:receitagora/models/billing_plan.dart';
import 'package:receitagora/services/billing/billing_exception.dart';
import 'package:receitagora/services/billing/billing_service.dart';

class StripeBillingService implements BillingService {
  StripeBillingService({
    required FirebaseFunctions functions,
  }) : _functions = functions;

  final FirebaseFunctions _functions;

  bool _initialized = false;
  String? _publishableKey;

  @override
  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }

    try {
      final plans = await fetchPlans();
      if (plans.isNotEmpty) {
        _initialized = true;
      }
    } catch (_) {
      // swallow initialization error to allow lazy retry later
    }
  }

  @override
  Future<List<BillingPlan>> fetchPlans() async {
    final callable = _functions.httpsCallable('billingListPlans');
    final response = await callable<Map<String, dynamic>>();
    final data = response.data;
    final publishableKey = data['publishableKey'] as String?;
    if (publishableKey != null && publishableKey.isNotEmpty) {
      await _applyPublishableKey(publishableKey);
    }

    final plans = data['plans'];
    if (plans is List) {
      return plans
          .map((dynamic item) {
            if (item is Map) {
              return BillingPlan.fromMap(
                Map<String, dynamic>.from(item as Map),
              );
            }
            return null;
          })
          .whereType<BillingPlan>()
          .toList(growable: false);
    }
    return const <BillingPlan>[];
  }

  @override
  Future<BillingResult> subscribe(BillingPlan plan) async {
    try {
      final callable =
          _functions.httpsCallable('billingCreateSubscriptionSession');
      final response = await callable<Map<String, dynamic>>(<String, dynamic>{
        'priceId': plan.priceId,
      });
      final data = response.data;
      final publishableKey = data['publishableKey'] as String?;
      if (publishableKey == null || publishableKey.isEmpty) {
        throw BillingException(
          'Configuração do Stripe indisponível no momento.',
          code: 'missing-publishable-key',
        );
      }

      await _applyPublishableKey(publishableKey);

      final customerId = data['customerId'] as String?;
      final ephemeralKey = data['ephemeralKey'] as String?;
      final clientSecret = data['paymentIntentClientSecret'] as String?;
      final subscriptionId = data['subscriptionId'] as String?;

      if (customerId == null ||
          ephemeralKey == null ||
          clientSecret == null ||
          subscriptionId == null) {
        throw BillingException(
          'Não foi possível iniciar a cobrança. Tente novamente em instantes.',
          code: 'invalid-session',
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: data['merchantDisplayName'] as String? ??
              'Receita Agora',
          allowsDelayedPaymentMethods: true,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final finalizeCallable =
          _functions.httpsCallable('billingFinalizeSubscription');
      await finalizeCallable<Map<String, dynamic>>(<String, dynamic>{
        'subscriptionId': subscriptionId,
      });

      return BillingResult(completed: true, subscriptionId: subscriptionId);
    } on StripeException catch (error) {
      final failureCode = error.error.code;
      if (failureCode == FailureCode.Canceled) {
        return const BillingResult(
          completed: false,
          message: 'Pagamento cancelado pelo usuário.',
        );
      }
      throw BillingException(
        error.error.message ??
            'Não foi possível concluir a assinatura. Verifique seus dados e tente novamente.',
        code: failureCode.name,
      );
    } on FirebaseFunctionsException catch (error) {
      throw BillingException(
        error.message ??
            'Não foi possível comunicar com o servidor de cobrança.',
        code: error.code,
      );
    } catch (_) {
      throw BillingException(
        'Ocorreu um erro inesperado durante a assinatura. Tente novamente mais tarde.',
      );
    }
  }

  @override
  Future<BillingPortalSession> createPortalSession() async {
    try {
      final callable = _functions.httpsCallable('billingCreatePortalSession');
      final response = await callable<Map<String, dynamic>>();
      return BillingPortalSession.fromMap(response.data);
    } on FirebaseFunctionsException catch (error) {
      throw BillingException(
        error.message ?? 'Não foi possível abrir o portal de assinatura agora.',
        code: error.code,
      );
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final callable = _functions.httpsCallable('billingCancelSubscription');
      await callable<void>(<String, dynamic>{
        'subscriptionId': subscriptionId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw BillingException(
        error.message ??
            'Não foi possível solicitar o cancelamento da assinatura neste momento.',
        code: error.code,
      );
    }
  }

  Future<void> _applyPublishableKey(String key) async {
    if (_publishableKey == key) {
      return;
    }
    _publishableKey = key;
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings(
      const StripeSettings(merchantDisplayName: 'Receita Agora'),
    );
  }
}
