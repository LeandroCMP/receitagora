import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

import 'recipe_history_service.dart';

class RecipeHistoryServiceImpl extends GetxService
    implements RecipeHistoryService {
  RecipeHistoryServiceImpl({required SharedPreferences preferences})
      : _preferences = preferences {
    _hydrateHistory();
  }

  final SharedPreferences _preferences;

  static const String _prefix = 'recipes.history';
  static const String _historyIndexKey = 'recipes.history.index';
  static const int _maxEntries = 20;

  final RxList<RecipeHistoryEntry> _history = <RecipeHistoryEntry>[].obs;

  @override
  List<RecipeHistoryEntry> get history =>
      List<RecipeHistoryEntry>.unmodifiable(_history);

  @override
  Stream<List<RecipeHistoryEntry>> get historyStream => _history.stream;

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

    final now = DateTime.now();
    final payload = <String, dynamic>{
      'timestamp': now.toUtc().toIso8601String(),
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

    final entry = RecipeHistoryEntry(
      cacheKey: cacheKey,
      ingredients: sanitizedIngredients,
      timestamp: now,
      totalRecipes: recipes.length,
    );
    await _upsertEntry(entry);
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
          : DateTime.tryParse(timestampRaw)?.toLocal() ?? DateTime.now();
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

  @override
  Future<void> removeEntry(String cacheKey) async {
    final updated = List<RecipeHistoryEntry>.from(_history)
      ..removeWhere((entry) => entry.cacheKey == cacheKey);
    _history.assignAll(updated);
    await _preferences.remove(_buildKey(cacheKey));
    await _persistHistory(updated);
  }

  @override
  Future<void> clearHistory() async {
    final entries = List<RecipeHistoryEntry>.from(_history);
    for (final entry in entries) {
      await _preferences.remove(_buildKey(entry.cacheKey));
    }
    _history.clear();
    await _preferences.remove(_historyIndexKey);
  }

  String _buildKey(String cacheKey) => '$_prefix::$cacheKey';

  List<String> _readList(dynamic value) {
    if (value is Iterable) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    return const <String>[];
  }

  void _hydrateHistory() {
    final raw = _preferences.getString(_historyIndexKey);
    if (raw == null || raw.isEmpty) {
      _history.clear();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Iterable) {
        _history.clear();
        return;
      }

      final List<RecipeHistoryEntry> entries = <RecipeHistoryEntry>[];
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          final cacheKey = item['cacheKey'] as String?;
          final timestampRaw = item['timestamp'] as String?;
          final timestamp =
              timestampRaw == null ? null : DateTime.tryParse(timestampRaw);
          if (cacheKey == null || timestamp == null) {
            continue;
          }
          entries.add(
            RecipeHistoryEntry(
              cacheKey: cacheKey,
              ingredients: _readList(item['ingredients']),
              timestamp: timestamp.toLocal(),
              totalRecipes: item['totalRecipes'] as int? ?? 0,
            ),
          );
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item as Map);
          final cacheKey = map['cacheKey'] as String?;
          final timestampRaw = map['timestamp'] as String?;
          final timestamp =
              timestampRaw == null ? null : DateTime.tryParse(timestampRaw);
          if (cacheKey == null || timestamp == null) {
            continue;
          }
          entries.add(
            RecipeHistoryEntry(
              cacheKey: cacheKey,
              ingredients: _readList(map['ingredients']),
              timestamp: timestamp.toLocal(),
              totalRecipes: map['totalRecipes'] as int? ?? 0,
            ),
          );
        }
      }

      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }
      _history.assignAll(entries);
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao carregar índice do histórico: $error\n$stackTrace',
        isError: true,
      );
      _history.clear();
    }
  }

  Future<void> _upsertEntry(RecipeHistoryEntry entry) async {
    final updated = List<RecipeHistoryEntry>.from(_history)
      ..removeWhere((item) => item.cacheKey == entry.cacheKey);
    updated.insert(0, entry);
    if (updated.length > _maxEntries) {
      updated.removeRange(_maxEntries, updated.length);
    }
    _history.assignAll(updated);
    await _persistHistory(updated);
  }

  Future<void> _persistHistory(List<RecipeHistoryEntry> entries) async {
    final payload = entries
        .map((entry) => <String, dynamic>{
              'cacheKey': entry.cacheKey,
              'ingredients': entry.ingredients,
              'timestamp': entry.timestamp.toUtc().toIso8601String(),
              'totalRecipes': entry.totalRecipes,
            })
        .toList();
    await _preferences.setString(_historyIndexKey, jsonEncode(payload));
  }
}
