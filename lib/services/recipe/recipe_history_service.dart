import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

class RecipeHistoryEntry {
  const RecipeHistoryEntry({
    required this.cacheKey,
    required this.ingredients,
    required this.timestamp,
    required this.totalRecipes,
  });

  final String cacheKey;
  final List<String> ingredients;
  final DateTime timestamp;
  final int totalRecipes;
}

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
  List<RecipeHistoryEntry> get history;
  Stream<List<RecipeHistoryEntry>> get historyStream;

  Future<void> cacheResult({
    required String cacheKey,
    required List<String> ingredients,
    required List<RecipeEntity> recipes,
  });

  Future<RecipeHistoryResult?> fetchLastResult(String cacheKey);
  Future<void> removeEntry(String cacheKey);
  Future<void> clearHistory();
}
