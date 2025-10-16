import 'package:receitagora/models/user_model.dart';

import '../entities/recipe_entity.dart';

abstract class RecipeRepository {
  Future<List<RecipeEntity>> generateRecipes({
    required List<String> ingredients,
    UserModel? user,
  });
}
