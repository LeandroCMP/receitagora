import 'package:flutter/foundation.dart';

@immutable
class IngredientLabRequest {
  IngredientLabRequest({
    required String ingredient,
    String? dishContext,
    Iterable<String>? availableIngredients,
    Iterable<String>? restrictions,
    String? desiredOutcome,
    String? notes,
  })  : ingredient = ingredient.trim(),
        dishContext = _normalizeOptional(dishContext),
        availableIngredients = _normalizeList(availableIngredients),
        restrictions = _normalizeList(restrictions),
        desiredOutcome = _normalizeOptional(desiredOutcome),
        notes = _normalizeOptional(notes);

  final String ingredient;
  final String? dishContext;
  final List<String> availableIngredients;
  final List<String> restrictions;
  final String? desiredOutcome;
  final String? notes;

  bool get hasAvailableIngredients => availableIngredients.isNotEmpty;
  bool get hasRestrictions => restrictions.isNotEmpty;

  IngredientLabRequest copyWith({
    String? ingredient,
    String? dishContext,
    Iterable<String>? availableIngredients,
    Iterable<String>? restrictions,
    String? desiredOutcome,
    String? notes,
  }) {
    return IngredientLabRequest(
      ingredient: ingredient ?? this.ingredient,
      dishContext: dishContext ?? this.dishContext,
      availableIngredients: availableIngredients ?? this.availableIngredients,
      restrictions: restrictions ?? this.restrictions,
      desiredOutcome: desiredOutcome ?? this.desiredOutcome,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ingredient': ingredient,
      'dishContext': dishContext,
      'availableIngredients': availableIngredients,
      'restrictions': restrictions,
      'desiredOutcome': desiredOutcome,
      'notes': notes,
    };
  }

  static String? _normalizeOptional(String? value) {
    if (value == null) {
      return null;
    }
    final sanitized = value.trim();
    return sanitized.isEmpty ? null : sanitized;
  }

  static List<String> _normalizeList(Iterable<String>? values) {
    if (values == null) {
      return const <String>[];
    }
    final filtered = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map((value) => value.toLowerCase())
        .toSet()
        .map((value) => value[0].toUpperCase() + value.substring(1))
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(filtered);
  }
}
