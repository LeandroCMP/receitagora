import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment_config.dart';
import '../errors/app_exception.dart';

class OpenAIService {
  OpenAIService({required this.client, required this.config});

  final http.Client client;
  final EnvironmentConfig config;

  Future<String> generateRecipes(List<String> ingredients) async {
    if (!config.hasValidCredentials) {
      return _simulateRecipes(ingredients);
    }

    final uri = Uri.parse('${config.openAIBaseUrl}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.openAIApiKey}',
    };

    final payload = jsonEncode({
      'model': config.model,
      'temperature': 0.7,
      'messages': [
        {
          'role': 'system',
          'content':
              'Você é um assistente culinário especializado em sugerir receitas brasileiras rápidas. Sempre retorne um JSON seguindo o schema fornecido pelo usuário.',
        },
        {
          'role': 'user',
          'content': _buildPrompt(ingredients),
        },
      ],
    });

    try {
      final response = await client.post(uri, headers: headers, body: payload);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw const AppException('Resposta vazia da OpenAI');
        }
        final message = choices.first['message'] as Map<String, dynamic>?
            ?? (throw const AppException('Formato inesperado da OpenAI'));
        final content = message['content'] as String?;
        if (content == null) {
          throw const AppException('Conteúdo ausente na resposta da OpenAI');
        }
        return content;
      }
      throw AppException('Erro ${response.statusCode} ao consultar OpenAI', details: response.body);
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw AppException('Falha ao comunicar com a OpenAI', details: error.toString());
    }
  }

  String _buildPrompt(List<String> ingredients) {
    final ingredientList = ingredients.map((ingredient) => '- ${ingredient.trim()}').join('\n');
    return '''Considere apenas os ingredientes abaixo para criar até três receitas. Ingredientes genéricos como sal, água, óleo e temperos básicos podem ser adicionados.

Ingredientes disponíveis:
$ingredientList

Retorne um JSON com o formato:
{
  "recipes": [
    {
      "name": "nome da receita",
      "description": "breve descrição",
      "ingredients": ["ingrediente 1", "ingrediente 2"],
      "steps": ["passo 1", "passo 2"]
    }
  ]
}

Certifique-se de que cada receita use somente os ingredientes informados (além dos genéricos permitidos).''';
  }

  String _simulateRecipes(List<String> ingredients) {
    final safeIngredients = ingredients.isEmpty ? ['ingrediente principal'] : ingredients;
    final sampleRecipes = {
      'recipes': [
        {
          'name': 'Salada crocante de ${safeIngredients.take(1).join(', ')}',
          'description':
              'Uma salada leve que aproveita os ingredientes disponíveis com um toque cítrico.',
          'ingredients': [...safeIngredients, 'Sal', 'Pimenta-do-reino', 'Azeite'],
          'steps': [
            'Higienize e prepare os ingredientes.',
            'Misture tudo em uma tigela com temperos a gosto.',
          ],
        },
        {
          'name': 'Refogado rápido de ${safeIngredients.join(', ')}',
          'description': 'Receita prática feita em uma única panela.',
          'ingredients': [...safeIngredients, 'Óleo', 'Água'],
          'steps': [
            'Aqueça o óleo e doure os ingredientes aromáticos.',
            'Adicione os demais itens e cozinhe até ficar macio.',
          ],
        },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(sampleRecipes);
  }
}
