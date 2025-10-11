import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'login_bindings.dart';
import 'login_page.dart';

class LoginModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginPage(),
          binding: LoginBindings(),
        ),
      ];
}
