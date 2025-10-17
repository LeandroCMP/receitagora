import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'paywall_bindings.dart';
import 'paywall_page.dart';

class PaywallModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.paywall,
          page: () => const PaywallPage(),
          binding: PaywallBindings(),
        ),
      ];
}
