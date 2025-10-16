import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

class ShareFailure implements Exception {
  ShareFailure(this.message);

  final String message;
}

enum ShareOutcome {
  shared,
  dismissed,
}

abstract class RecipeShareService {
  Future<ShareOutcome> shareRecipe(RecipeEntity recipe);
}
