import 'dart:convert';

import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/openai/openai_service.dart';

import 'package:receitagora/modules/recipe_finder/data/models/recipe_model.dart';

class RecipeRemoteDataSource {
  RecipeRemoteDataSource({required this.service});

  final OpenAIService service;

  static const Set<String> _defaultPantryItems = {
    'sal',
    'sal a gosto',
    'sal grosso',
    'sal marinho',
    'agua',
    'água',
    'oleo',
    'óleo',
    'óleo vegetal',
    'azeite',
    'azeite de oliva',
    'acucar',
    'açúcar',
    'açúcar refinado',
    'açúcar mascavo',
    'pimenta',
    'pimenta do reino',
    'temperos',
    'temperos a gosto',
  };

  Future<List<RecipeModel>> generateRecipes({
    required List<String> ingredients,
    UserModel? user,
  }) async {
    final content = await service.generateRecipes(
      ingredients,
      user: user,
    );
    final jsonContent = _extractJson(content);

    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;
      final recipes = (map['recipes'] as List<dynamic>? ?? const [])
          .map((dynamic item) => RecipeModel.fromMap(item as Map<String, dynamic>))
          .toList();
      if (recipes.isEmpty) {
        throw const AppException('Nenhuma receita encontrada na resposta da IA.');
      }
      final sanitizedRecipes = _sanitizeRecipes(recipes, ingredients);
      if (sanitizedRecipes.isEmpty) {
        throw const AppException(
          'Nenhuma receita válida foi encontrada com os ingredientes informados.',
        );
      }
      return sanitizedRecipes;
    } catch (error) {
      throw AppException('Falha ao interpretar receitas da IA', details: error.toString());
    }
  }

  String _extractJson(String content) {
    var trimmed = content.trim();
    if (trimmed.startsWith('```')) {
      final lines = trimmed.split('\n');
      if (lines.isNotEmpty) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.trim() == '```') {
        lines.removeLast();
      }
      trimmed = lines.join('\n');
    }

    final startIndex = trimmed.indexOf('{');
    final endIndex = trimmed.lastIndexOf('}');
    if (startIndex == -1 || endIndex == -1) {
      throw const AppException('JSON não encontrado na resposta da IA.');
    }
    return trimmed.substring(startIndex, endIndex + 1);
  }

  List<RecipeModel> _sanitizeRecipes(
    List<RecipeModel> recipes,
    List<String> baseIngredients,
  ) {
    final allowed = <String>{};

    void addNormalized(String value) {
      final normalized = _normalize(value);
      if (normalized.isEmpty) {
        return;
      }
      allowed.add(normalized);
      for (final part in normalized.split(' ')) {
        if (part.length >= 4) {
          allowed.add(part);
        }
      }
    }

    for (final item in baseIngredients) {
      addNormalized(item);
    }
    for (final pantry in _defaultPantryItems) {
      addNormalized(pantry);
    }

    return recipes
        .map((recipe) {
          final sanitizedIngredients = <String>[];
          final seen = <String>{};
          for (final ingredient in recipe.ingredients) {
            final normalized = _normalize(ingredient);
            if (normalized.isEmpty) {
              continue;
            }
            if (!_matchesAllowedIngredient(normalized, allowed)) {
              continue;
            }
            if (seen.add(normalized)) {
              sanitizedIngredients.add(ingredient.trim());
            }
          }

          if (sanitizedIngredients.isEmpty) {
            return null;
          }

          return RecipeModel(
            name: recipe.name,
            description: recipe.description,
            ingredients: sanitizedIngredients,
            steps: recipe.steps
                .map((step) => step.trim())
                .where((step) => step.isNotEmpty)
                .toList(),
            difficulty: recipe.difficulty,
            duration: recipe.duration,
          );
        })
        .whereType<RecipeModel>()
        .toList();
  }

  String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      buffer.write(_normalizeChar(codeUnit));
    }
    final normalized = buffer.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeChar(int codeUnit) {
    switch (codeUnit) {
      case 225: // á
      case 224: // à
      case 227: // ã
      case 226: // â
      case 228: // ä
        return 'a';
      case 233: // é
      case 232: // è
      case 234: // ê
      case 235: // ë
        return 'e';
      case 237: // í
      case 236: // ì
      case 238: // î
      case 239: // ï
        return 'i';
      case 243: // ó
      case 242: // ò
      case 244: // ô
      case 245: // õ
      case 246: // ö
        return 'o';
      case 250: // ú
      case 249: // ù
      case 251: // û
      case 252: // ü
        return 'u';
      case 241: // ñ
        return 'n';
      case 231: // ç
        return 'c';
      default:
        return String.fromCharCode(codeUnit);
    }
  }

  bool _matchesAllowedIngredient(String candidate, Set<String> allowed) {
    if (allowed.contains(candidate)) {
      return true;
    }
    for (final allowedItem in allowed) {
      if (allowedItem.isEmpty) {
        continue;
      }
      if (candidate.contains(' $allowedItem ') ||
          candidate.startsWith('$allowedItem ') ||
          candidate.endsWith(' $allowedItem') ||
          allowedItem.contains(' $candidate ') ||
          allowedItem.startsWith('$candidate ') ||
          allowedItem.endsWith(' $candidate') ||
          candidate == allowedItem ||
          allowedItem == candidate) {
        return true;
      }
      if (candidate.contains(allowedItem) && allowedItem.length >= 4) {
        return true;
      }
      if (allowedItem.contains(candidate) && candidate.length >= 4) {
        return true;
      }
    }
    return false;
  }

}
