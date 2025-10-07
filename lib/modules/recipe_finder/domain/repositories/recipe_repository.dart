import '../entities/recipe_entity.dart';

abstract class RecipeRepository {
  Future<List<RecipeEntity>> generateRecipes(List<String> ingredients);
}
