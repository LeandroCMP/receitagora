import 'package:get/get.dart';

import 'package:receitagora/services/billing/billing_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'paywall_controller.dart';

class PaywallBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaywallController>(
      () => PaywallController(
        billingService: Get.find<BillingService>(),
        sessionService: Get.find<SessionService>(),
      ),
    );
  }
}
