import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'splash_bindings.dart';
import 'splash_page.dart';

class SplashModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashPage(),
          binding: SplashBindings(),
        ),
      ];
}
