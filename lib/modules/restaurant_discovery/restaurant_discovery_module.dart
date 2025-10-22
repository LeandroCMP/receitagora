import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'restaurant_discovery_bindings.dart';
import 'restaurant_discovery_page.dart';

class RestaurantDiscoveryModule implements Module {
  @override
  List<GetPage<dynamic>> get routers => [
        GetPage(
          name: AppRoutes.restaurantDiscovery,
          page: () => const RestaurantDiscoveryPage(),
          binding: RestaurantDiscoveryBindings(),
        ),
      ];
}
