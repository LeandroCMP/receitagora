import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'user_profile_bindings.dart';
import 'user_profile_page.dart';

class UserProfileModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.userProfile,
          page: () => const UserProfilePage(),
          binding: UserProfileBindings(),
        ),
      ];
}
