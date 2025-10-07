import 'package:get/get.dart';

import '../../../../core/services/openai_service.dart';
import '../../../../core/services/session_service.dart';
import '../../data/datasources/recipe_remote_data_source.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/usecases/generate_recipes_usecase.dart';
import '../controllers/recipe_finder_controller.dart';

class RecipeFinderBinding extends Bindings {
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
      ),
    );
  }
}
