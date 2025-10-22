import 'package:get/get.dart';

import 'package:receitagora/services/billing/billing_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'premium_plans_controller.dart';

class PremiumPlansBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PremiumPlansController>(
      () => PremiumPlansController(
        billingService: Get.find<BillingService>(),
        sessionService: Get.find<SessionService>(),
      ),
    );
  }
}
