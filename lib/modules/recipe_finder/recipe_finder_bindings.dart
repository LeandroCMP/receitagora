import 'package:get/get.dart';

import 'package:receitagora/modules/recipe_finder/data/datasources/recipe_remote_data_source.dart';
import 'package:receitagora/modules/recipe_finder/data/repositories/recipe_repository_impl.dart';
import 'package:receitagora/modules/recipe_finder/domain/repositories/recipe_repository.dart';
import 'package:receitagora/modules/recipe_finder/domain/usecases/generate_recipes_usecase.dart';
import 'package:receitagora/services/openai/openai_service.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'recipe_finder_controller.dart';

class RecipeFinderBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecipeRemoteDataSource>(
      () => RecipeRemoteDataSource(service: Get.find<OpenAIService>()),
    );
    Get.lazyPut<RecipeRepository>(
      () => RecipeRepositoryImpl(remoteDataSource: Get.find<RecipeRemoteDataSource>()),
    );
    Get.lazyPut<GenerateRecipesUseCase>(
      () => GenerateRecipesUseCase(Get.find<RecipeRepository>()),
    );
    Get.lazyPut<RecipeFinderController>(
      () => RecipeFinderController(
        generateRecipesUseCase: Get.find<GenerateRecipesUseCase>(),
        sessionService: Get.find<SessionService>(),
        recipeHistoryService: Get.find<RecipeHistoryService>(),
      ),
    );
  }
}
