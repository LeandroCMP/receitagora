import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'premium_plans_bindings.dart';
import 'premium_plans_page.dart';
import 'billing_portal_page.dart';

class PremiumPlansModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.premiumPlans,
          page: () => const PremiumPlansPage(),
          binding: PremiumPlansBindings(),
        ),
        GetPage(
          name: AppRoutes.billingPortal,
          page: () => const BillingPortalPage(),
        ),
      ];
}
