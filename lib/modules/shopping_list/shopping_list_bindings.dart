import 'package:get/get.dart';

import 'package:receitagora/services/recipe/recipe_history_service.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';

import 'shopping_list_detail_controller.dart';
import 'shopping_lists_controller.dart';

class ShoppingListsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShoppingListsController>(
      () => ShoppingListsController(
        shoppingListService: Get.find<ShoppingListService>(),
        historyService: Get.find<RecipeHistoryService>(),
      ),
    );
  }
}

class ShoppingListDetailBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShoppingListDetailController>(() {
      final args = Get.arguments;
      if (args is! ShoppingListDetailArgs) {
        throw ArgumentError(
          'ShoppingListDetailArgs é obrigatório para abrir detalhes da lista.',
        );
      }
      return ShoppingListDetailController(
        args: args,
        shoppingListService: Get.find<ShoppingListService>(),
      );
    });
  }
}
