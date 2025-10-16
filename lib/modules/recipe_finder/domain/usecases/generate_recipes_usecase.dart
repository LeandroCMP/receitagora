import 'package:receitagora/models/user_model.dart';

import '../entities/recipe_entity.dart';
import '../repositories/recipe_repository.dart';

class GenerateRecipesUseCase {
  GenerateRecipesUseCase(this.repository);

  final RecipeRepository repository;

  Future<List<RecipeEntity>> call({
    required List<String> ingredients,
    UserModel? user,
  }) {
    final sanitized = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    if (sanitized.isEmpty) {
      return Future.value(const <RecipeEntity>[]);
    }

    return repository.generateRecipes(ingredients: sanitized, user: user);
  }
}
