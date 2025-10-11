import 'package:get/get.dart';

import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'favorites_controller.dart';

class FavoritesBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesController>(
      () => FavoritesController(
        sessionService: Get.find<SessionService>(),
        favoritesService: Get.find<RecipeFavoritesService>(),
      ),
    );
  }
}
