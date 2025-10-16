import 'dart:collection';

import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';

class FavoritesAnalytics {
  const FavoritesAnalytics({
    required this.totalFavorites,
    required this.uniqueIngredients,
    required this.uniqueTags,
    required this.topDifficulty,
    required this.lastFavorited,
    required this.tagCounts,
    required this.difficultyCounts,
  });

  final int totalFavorites;
  final int uniqueIngredients;
  final int uniqueTags;
  final String? topDifficulty;
  final DateTime? lastFavorited;
  final Map<String, int> tagCounts;
  final Map<String, int> difficultyCounts;

  static const FavoritesAnalytics empty = FavoritesAnalytics(
    totalFavorites: 0,
    uniqueIngredients: 0,
    uniqueTags: 0,
    topDifficulty: null,
    lastFavorited: null,
    tagCounts: <String, int>{},
    difficultyCounts: <String, int>{},
  );

  List<MapEntry<String, int>> get sortedTagEntries {
    final entries = tagCounts.entries.toList()
      ..sort((a, b) {
        final diff = b.value.compareTo(a.value);
        if (diff != 0) {
          return diff;
        }
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return UnmodifiableListView(entries);
  }

  String? get formattedLastFavorited {
    if (lastFavorited == null) {
      return null;
    }
    final local = lastFavorited!.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  int countForTag(String tag) => tagCounts[tag] ?? 0;

  FavoritesAnalytics copyWith({
    int? totalFavorites,
    int? uniqueIngredients,
    int? uniqueTags,
    String? topDifficulty,
    DateTime? lastFavorited,
    Map<String, int>? tagCounts,
    Map<String, int>? difficultyCounts,
  }) {
    return FavoritesAnalytics(
      totalFavorites: totalFavorites ?? this.totalFavorites,
      uniqueIngredients: uniqueIngredients ?? this.uniqueIngredients,
      uniqueTags: uniqueTags ?? this.uniqueTags,
      topDifficulty: topDifficulty ?? this.topDifficulty,
      lastFavorited: lastFavorited ?? this.lastFavorited,
      tagCounts: tagCounts ?? this.tagCounts,
      difficultyCounts: difficultyCounts ?? this.difficultyCounts,
    );
  }

  Map<String, dynamic> toSerializableMap() {
    final sortedTagEntries = tagCounts.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    final sortedDifficultyEntries = difficultyCounts.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return <String, dynamic>{
      'totalFavorites': totalFavorites,
      'uniqueIngredients': uniqueIngredients,
      'uniqueTags': uniqueTags,
      'topDifficulty': topDifficulty,
      'lastFavorited': lastFavorited?.toIso8601String(),
      'tagCounts': Map<String, int>.fromEntries(sortedTagEntries),
      'difficultyCounts': Map<String, int>.fromEntries(sortedDifficultyEntries),
    };
  }

  factory FavoritesAnalytics.fromFavorites(
    List<FavoritedRecipeEntity> favorites,
  ) {
    final ingredientSet = <String>{};
    final difficultyCounts = <String, int>{};
    final tagCounts = <String, int>{};
    DateTime? last;

    for (final favorite in favorites) {
      ingredientSet.addAll(
        favorite.recipe.ingredients
            .map((item) => item.trim().toLowerCase())
            .where((item) => item.isNotEmpty),
      );

      final difficulty = favorite.recipe.difficulty.trim();
      if (difficulty.isNotEmpty) {
        difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
      }

      final favoritedAt = favorite.favoritedAt;
      if (favoritedAt != null) {
        if (last == null || favoritedAt.isAfter(last)) {
          last = favoritedAt;
        }
      }

      for (final tag in favorite.tags) {
        final sanitized = tag.trim();
        if (sanitized.isEmpty) {
          continue;
        }
        tagCounts[sanitized] = (tagCounts[sanitized] ?? 0) + 1;
      }
    }

    String? topDifficulty;
    if (difficultyCounts.isNotEmpty) {
      final sorted = difficultyCounts.entries.toList()
        ..sort((a, b) {
          final diff = b.value.compareTo(a.value);
          if (diff != 0) {
            return diff;
          }
          return a.key.toLowerCase().compareTo(b.key.toLowerCase());
        });
      topDifficulty = sorted.first.key;
    }

    return FavoritesAnalytics(
      totalFavorites: favorites.length,
      uniqueIngredients: ingredientSet.length,
      uniqueTags: tagCounts.length,
      topDifficulty: topDifficulty,
      lastFavorited: last,
      tagCounts: Map<String, int>.unmodifiable(tagCounts),
      difficultyCounts: Map<String, int>.unmodifiable(difficultyCounts),
    );
  }
}
