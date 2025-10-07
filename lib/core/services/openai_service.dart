import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment_config.dart';
import '../errors/app_exception.dart';

class OpenAIService {
  OpenAIService({required this.client, required this.config});

  final http.Client client;
  final EnvironmentConfig config;

  Future<String> generateRecipes(List<String> ingredients) async {
    final sanitized = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    AppException? failure;

    if (config.hasValidCredentials) {
      try {
        final content = await _requestRecipesFromOpenAI(sanitized);
        if (content != null && content.trim().isNotEmpty) {
          return content;
        }
        failure = const AppException('Resposta vazia da OpenAI');
      } on AppException catch (error) {
        failure = error;
      } catch (error) {
        failure = AppException(
          'Falha ao comunicar com a OpenAI',
          details: error.toString(),
        );
      }
    } else {
      failure = const AppException('Chave da OpenAI ausente ou inválida.');
    }

    return _generateFallbackRecipes(sanitized, failure: failure);
  }

  Future<String?> _requestRecipesFromOpenAI(List<String> ingredients) async {
    final uri = Uri.parse('${config.openAIBaseUrl}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.openAIApiKey}',
    };

    final payload = jsonEncode({
      'model': config.model,
      'temperature': 0.7,
      'response_format': {
        'type': 'json_object',
      },
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

    final response = await _postWithRetry(
      uri,
      headers: headers,
      body: payload,
    );

    if (response.statusCode == 429) {
      throw _mapRateLimitError(response);
    }
    if (response.statusCode == 400) {
      throw _mapBadRequestError(response);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return null;
      }
      final message = choices.first['message'] as Map<String, dynamic>?;
      if (message == null) {
        return null;
      }
      final content = _readMessageContent(message['content']);
      if (content == null) {
        return null;
      }
      final trimmed = content.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    throw AppException(
      'Erro ${response.statusCode} ao consultar OpenAI',
      details: response.body,
    );
  }

  AppException _mapRateLimitError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code']?.toString().toLowerCase();
        final message = error['message']?.toString() ?? '';

        if (code == 'insufficient_quota' ||
            code == 'billing_hard_limit_reached' ||
            message.contains('insufficient_quota')) {
          return const AppException(
            'Sua conta da OpenAI atingiu o limite de uso. Verifique seu plano ou créditos disponíveis no painel da OpenAI.',
          );
        }

        if (code == 'rate_limit_exceeded' ||
            message.contains('rate limit') ||
            message.contains('too many requests')) {
          return const AppException(
            'A OpenAI está recebendo muitas requisições, aguarde e tente novamente.',
          );
        }
      }
    } catch (_) {
      // Ignored: fallback message will be returned below.
    }

    return const AppException(
      'Não foi possível processar sua solicitação na OpenAI. Tente novamente mais tarde ou confira se há créditos suficientes.',
    );
  }

  AppException _mapBadRequestError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code']?.toString().toLowerCase();
        final message = error['message']?.toString() ?? '';

        if (code == 'context_length_exceeded' ||
            message.contains('context length') ||
            message.contains('maximum context')) {
          return const AppException(
            'O pedido excedeu o limite de tokens aceitos pelo modelo. Reduza a lista de ingredientes e tente novamente.',
          );
        }

        if (message.contains('Unrecognized request argument') &&
            message.contains('response_format')) {
          return const AppException(
            'O modelo configurado não aceita respostas em JSON. Atualize a variável OPENAI_MODEL para um modelo compatível, como gpt-4o-mini.',
          );
        }

        if (message.contains('Invalid URL') || message.contains('invalid url')) {
          return const AppException(
            'Verifique a variável OPENAI_BASE_URL. Ela deve apontar para o endpoint correto (por exemplo, https://api.openai.com/v1).',
          );
        }

        if (message.isNotEmpty) {
          return AppException(
            'Não foi possível processar sua solicitação na OpenAI: $message',
            details: response.body,
          );
        }
      }
    } catch (_) {
      // Ignorado: o fallback abaixo trata o cenário.
    }

    return const AppException(
      'A OpenAI rejeitou a solicitação enviada. Confira os dados informados e tente novamente.',
    );
  }

  Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    int maxAttempts = 3,
  }) async {
    const baseDelay = Duration(milliseconds: 500);

    http.Response? lastResponse;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final response =
          await client.post(uri, headers: headers, body: body);
      if (response.statusCode != 429) {
        return response;
      }

      lastResponse = response;
      if (attempt == maxAttempts - 1) {
        break;
      }

      final retryAfter = response.headers['retry-after'];
      final delay = _parseRetryAfter(retryAfter) ??
          Duration(milliseconds: baseDelay.inMilliseconds * (1 << attempt));
      await Future.delayed(delay);
    }

    return lastResponse ??
        await client.post(uri, headers: headers, body: body);
  }

  Duration? _parseRetryAfter(String? header) {
    if (header == null) {
      return null;
    }

    final seconds = int.tryParse(header);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    final date = DateTime.tryParse(header);
    if (date != null) {
      final now = DateTime.now().toUtc();
      final target = date.toUtc();
      final difference = target.difference(now);
      if (difference.isNegative) {
        return Duration.zero;
      }
      return difference;
    }

    return null;
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

  String? _readMessageContent(dynamic content) {
    if (content is String) {
      return content;
    }
    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String) {
            buffer.write(text);
          }
        }
      }
      return buffer.isEmpty ? null : buffer.toString();
    }
    return null;
  }

  String _generateFallbackRecipes(
    List<String> ingredients, {
    AppException? failure,
  }) {
    final normalized = LinkedHashSet<String>.from(ingredients);
    if (normalized.isEmpty) {
      normalized.add('ingredientes variados');
    }

    final uniqueIngredients = normalized.toList();
    final recipes = _buildFallbackRecipeList(uniqueIngredients);

    final payload = <String, dynamic>{
      'recipes': recipes,
      'metadata': {
        'source': 'fallback',
        if (failure != null) 'reason': failure.message,
      },
    };

    return jsonEncode(payload);
  }

  List<Map<String, dynamic>> _buildFallbackRecipeList(List<String> ingredients) {
    final main = ingredients.first;
    final extras = ingredients.skip(1).toList();

    final recipes = <Map<String, dynamic>>[
      _buildOnePanRecipe(main, extras),
      _buildOvenRecipe(main, extras),
      _buildFreshBowlRecipe(main, extras),
    ];

    final uniqueRecipes = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final recipe in recipes) {
      final name = recipe['name'] as String? ?? '';
      if (name.isEmpty || uniqueRecipes.add(name)) {
        result.add(recipe);
      }
    }

    return result.take(3).toList();
  }

  Map<String, dynamic> _buildOnePanRecipe(
    String main,
    List<String> extras,
  ) {
    final featured = <String>[main, if (extras.isNotEmpty) extras.first];
    final allIngredients = _combineIngredients(featured)
      ..add('alho picado (opcional)');

    return {
      'name': 'Refogado caseiro de ${_formatList(featured)}',
      'description':
          'Receita rápida feita na panela com ${_formatList(featured)} temperados com básicos da despensa.',
      'ingredients': allIngredients,
      'steps': [
        'Aqueça uma panela com um fio de azeite de oliva.',
        'Adicione ${_formatList(featured)} e refogue em fogo médio até ficar macio.',
        'Tempere com sal, pimenta-do-reino e alho opcional, mexendo por mais 2 minutos antes de servir.',
      ],
    };
  }

  Map<String, dynamic> _buildOvenRecipe(
    String main,
    List<String> extras,
  ) {
    final supporting = extras.isNotEmpty ? extras : [main];
    final highlighted = [main, ...supporting.take(2)];
    final ingredients = _combineIngredients(highlighted)
      ..add('ervas secas ou temperos a gosto');

    return {
      'name': 'Assado prático de ${_formatList(highlighted)}',
      'description':
          'Uma versão de forno que aproveita ${_formatList(highlighted)} com temperos simples.',
      'ingredients': ingredients,
      'steps': [
        'Preaqueça o forno a 200 °C e unte uma assadeira com azeite.',
        'Distribua ${_formatList(highlighted)} na assadeira e tempere com sal, pimenta e ervas.',
        'Asse por 20 a 25 minutos, mexendo na metade do tempo para dourar por igual.',
      ],
    };
  }

  Map<String, dynamic> _buildFreshBowlRecipe(
    String main,
    List<String> extras,
  ) {
    final base = extras.isNotEmpty ? extras.last : main;
    final complement = <String>{main, base, ...extras};
    final complementList = complement.toList();
    final ingredients = _combineIngredients(complementList)
      ..add('suco de limão ou vinagre a gosto');

    return {
      'name': 'Tigela fresca de ${_formatList(complementList)}',
      'description':
          'Combinação leve de ${_formatList(complementList)} finalizada com toque cítrico.',
      'ingredients': ingredients,
      'steps': [
        'Pique ${_formatList(complementList)} em pedaços pequenos e coloque em uma tigela.',
        'Regue com azeite, adicione sal, pimenta e suco de limão ou vinagre.',
        'Misture bem e deixe descansar por 5 minutos antes de servir como salada ou acompanhamento.',
      ],
    };
  }

  List<String> _combineIngredients(Iterable<String> items) {
    final normalized = LinkedHashSet<String>.from(
      items.map((item) => item.trim()).where((item) => item.isNotEmpty),
    );
    for (final basic in const ['azeite de oliva', 'sal a gosto', 'pimenta-do-reino']) {
      normalized.add(basic);
    }
    return normalized.toList();
  }

  String _formatList(List<String> items) {
    final unique = LinkedHashSet<String>.from(
      items.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ).toList();
    if (unique.isEmpty) {
      return '';
    }
    if (unique.length == 1) {
      return unique.first;
    }
    if (unique.length == 2) {
      return '${unique[0]} e ${unique[1]}';
    }
    final head = unique.sublist(0, unique.length - 1).join(', ');
    return '$head e ${unique.last}';
  }
}
