import 'package:get/get.dart';

import 'package:receitagora/services/ingredient_lab/ingredient_lab_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'ingredient_lab_controller.dart';

class IngredientLabBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IngredientLabController>(
      () => IngredientLabController(
        labService: Get.find<IngredientLabService>(),
        sessionService: Get.find<SessionService>(),
      ),
    );
  }
}
