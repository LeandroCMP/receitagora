import 'package:get/get.dart';

import '../../../../core/services/recipe_favorites_service.dart';
import '../../../../core/services/session_service.dart';
import '../controllers/favorites_controller.dart';

class FavoritesBinding extends Bindings {
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
