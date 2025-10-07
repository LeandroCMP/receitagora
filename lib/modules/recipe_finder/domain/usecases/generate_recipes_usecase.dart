import '../entities/recipe_entity.dart';
import '../repositories/recipe_repository.dart';

class GenerateRecipesUseCase {
  GenerateRecipesUseCase(this.repository);

  final RecipeRepository repository;

  Future<List<RecipeEntity>> call(List<String> ingredients) {
    final sanitized = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    if (sanitized.isEmpty) {
      return Future.value(const <RecipeEntity>[]);
    }

    return repository.generateRecipes(sanitized);
  }
}
