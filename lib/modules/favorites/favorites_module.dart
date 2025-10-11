import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'favorites_bindings.dart';
import 'favorites_page.dart';

class FavoritesModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.favorites,
          page: () => const FavoritesPage(),
          binding: FavoritesBindings(),
        ),
      ];
}
