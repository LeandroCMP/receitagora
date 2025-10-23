import 'package:get/get.dart';

import 'package:receitagora/services/location/location_service.dart';
import 'package:receitagora/services/nutrition/nutrition_plan_service.dart';
import 'package:receitagora/services/restaurants/restaurant_discovery_service.dart';

import 'restaurant_discovery_controller.dart';

class RestaurantDiscoveryBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RestaurantDiscoveryController>(
      () => RestaurantDiscoveryController(
        discoveryService: Get.find<RestaurantDiscoveryService>(),
        locationService: Get.find<LocationService>(),
        nutritionPlanService: Get.find<NutritionPlanService>(),
      ),
    );
  }
}
