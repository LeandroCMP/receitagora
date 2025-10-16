import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

class RecipeHistoryResult {
  RecipeHistoryResult({
    required this.cacheKey,
    required this.recipes,
    required this.ingredients,
    required this.timestamp,
  });

  final String cacheKey;
  final List<RecipeEntity> recipes;
  final List<String> ingredients;
  final DateTime timestamp;
}

abstract class RecipeHistoryService {
  Future<void> cacheResult({
    required String cacheKey,
    required List<String> ingredients,
    required List<RecipeEntity> recipes,
  });

  Future<RecipeHistoryResult?> fetchLastResult(String cacheKey);
}
