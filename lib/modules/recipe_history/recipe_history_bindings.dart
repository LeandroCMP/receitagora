import 'package:get/get.dart';

import 'package:receitagora/services/recipe/recipe_history_service.dart';

import 'recipe_history_controller.dart';

class RecipeHistoryBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecipeHistoryController>(
      () => RecipeHistoryController(
        historyService: Get.find<RecipeHistoryService>(),
      ),
    );
  }
}
