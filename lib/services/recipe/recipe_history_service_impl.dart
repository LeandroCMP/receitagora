import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

import 'recipe_history_service.dart';

class RecipeHistoryServiceImpl extends GetxService
    implements RecipeHistoryService {
  RecipeHistoryServiceImpl({required SharedPreferences preferences})
      : _preferences = preferences;

  final SharedPreferences _preferences;

  static const String _prefix = 'recipes.history';

  @override
  Future<void> cacheResult({
    required String cacheKey,
    required List<String> ingredients,
    required List<RecipeEntity> recipes,
  }) async {
    if (recipes.isEmpty) {
      return;
    }

    final sanitizedIngredients = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'ingredients': sanitizedIngredients,
      'recipes': recipes
          .map((recipe) => <String, dynamic>{
                'name': recipe.name,
                'description': recipe.description,
                'difficulty': recipe.difficulty,
                'duration': recipe.duration,
                'ingredients': recipe.ingredients,
                'steps': recipe.steps,
              })
          .toList(),
    };

    final key = _buildKey(cacheKey);
    await _preferences.setString(key, jsonEncode(payload));
  }

  @override
  Future<RecipeHistoryResult?> fetchLastResult(String cacheKey) async {
    final key = _buildKey(cacheKey);
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final timestampRaw = decoded['timestamp'] as String?;
      final timestamp = timestampRaw == null
          ? DateTime.now()
          : DateTime.tryParse(timestampRaw) ?? DateTime.now();
      final ingredientsRaw = decoded['ingredients'];
      final ingredients = ingredientsRaw is Iterable
          ? ingredientsRaw.map((dynamic item) => item.toString()).toList()
          : const <String>[];
      final recipesRaw = decoded['recipes'];
      if (recipesRaw is! Iterable) {
        return null;
      }
      final recipes = recipesRaw
          .map((dynamic item) => item as Map<String, dynamic>)
          .map(
            (map) => RecipeEntity(
              name: map['name'] as String? ?? 'Receita sem nome',
              description:
                  map['description'] as String? ?? 'Descrição indisponível.',
              difficulty:
                  map['difficulty'] as String? ?? 'Dificuldade não informada',
              duration: map['duration'] as String? ?? 'Tempo não informado',
              ingredients: _readList(map['ingredients']),
              steps: _readList(map['steps']),
            ),
          )
          .toList();
      if (recipes.isEmpty) {
        return null;
      }

      return RecipeHistoryResult(
        cacheKey: cacheKey,
        recipes: recipes,
        ingredients: ingredients,
        timestamp: timestamp,
      );
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao ler histórico de receitas: $error\n$stackTrace',
        isError: true,
      );
      return null;
    }
  }

  String _buildKey(String cacheKey) => '$_prefix::$cacheKey';

  List<String> _readList(dynamic value) {
    if (value is Iterable) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }
}
