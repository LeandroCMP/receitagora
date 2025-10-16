import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

import 'favorites_analytics.dart';

class FavoritesFailure implements Exception {
  FavoritesFailure(this.message);

  final String message;
}

abstract class RecipeFavoritesService {
  static const int maxFavorites = 10;
  static const int maxTagsPerRecipe = 8;

  Stream<Set<String>> get favoriteIdsStream;
  Stream<List<FavoritedRecipeEntity>> get favoritesStream;
  Stream<FavoritesAnalytics> get analyticsStream;
  Set<String> get favoriteIds;
  List<FavoritedRecipeEntity> get favorites;
  FavoritesAnalytics get analytics;

  String favoriteIdFor(RecipeEntity recipe);
  bool isFavoriteSync(RecipeEntity recipe);
  Future<void> addFavorite(RecipeEntity recipe);
  Future<void> removeFavoriteForRecipe(RecipeEntity recipe);
  Future<void> removeFavoriteById(String id);
  Future<void> toggleFavorite(RecipeEntity recipe);
  Future<void> updateTags({required String favoriteId, required List<String> tags});
}
