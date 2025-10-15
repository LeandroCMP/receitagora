import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

class ShareFailure implements Exception {
  ShareFailure(this.message);

  final String message;
}

abstract class RecipeShareService {
  Future<void> shareRecipe(RecipeEntity recipe);
}
