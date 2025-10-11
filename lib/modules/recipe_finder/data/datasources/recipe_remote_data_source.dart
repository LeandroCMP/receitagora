import 'dart:convert';

import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/services/openai/openai_service.dart';

import 'package:receitagora/modules/recipe_finder/data/models/recipe_model.dart';

class RecipeRemoteDataSource {
  RecipeRemoteDataSource({required this.service});

  final OpenAIService service;

  Future<List<RecipeModel>> generateRecipes(List<String> ingredients) async {
    final content = await service.generateRecipes(ingredients);
    final jsonContent = _extractJson(content);

    try {
      final map = jsonDecode(jsonContent) as Map<String, dynamic>;
      final recipes = (map['recipes'] as List<dynamic>? ?? const [])
          .map((dynamic item) => RecipeModel.fromMap(item as Map<String, dynamic>))
          .toList();
      if (recipes.isEmpty) {
        throw const AppException('Nenhuma receita encontrada na resposta da IA.');
      }
      return recipes;
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
}
