import 'package:get/get.dart';

import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';

import 'favorites_notebook_detail_controller.dart';
import 'favorites_notebooks_controller.dart';

class FavoritesNotebooksBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesNotebooksController>(
      () => FavoritesNotebooksController(
        notebookService: Get.find<FavoritesNotebookService>(),
        favoritesService: Get.find<RecipeFavoritesService>(),
      ),
    );
  }
}

class FavoritesNotebookDetailBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesNotebookDetailController>(() {
      final args = Get.arguments;
      if (args is! FavoritesNotebookDetailArgs) {
        throw ArgumentError('FavoritesNotebookDetailArgs é obrigatório.');
      }
      return FavoritesNotebookDetailController(
        args: args,
        notebookService: Get.find<FavoritesNotebookService>(),
        favoritesService: Get.find<RecipeFavoritesService>(),
      );
    });
  }
}
