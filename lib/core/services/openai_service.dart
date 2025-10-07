import 'dart:async';
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

    if (!config.hasValidCredentials) {
      throw const AppException(
        'Chave da OpenAI ausente ou inválida. Configure a variável OPENAI_API_KEY para gerar receitas com a IA.',
      );
    }

    try {
      final content = await _requestRecipesFromOpenAI(sanitized);
      if (content != null && content.trim().isNotEmpty) {
        return content;
      }
      throw const AppException('A OpenAI retornou uma resposta vazia.');
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(
        'Falha ao comunicar com a OpenAI. Tente novamente em instantes.',
        details: error.toString(),
      );
    }
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
      // Ignored: mantemos a mensagem genérica definida abaixo.
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
      // Ignorado: mantemos a mensagem genérica definida abaixo.
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
    final ingredientList =
        ingredients.map((ingredient) => '- ${ingredient.trim()}').join('\n');
    return '''Considere apenas os ingredientes abaixo para criar até três receitas. Ingredientes genéricos como sal, água, óleo e temperos básicos podem ser adicionados.

Ingredientes disponíveis:
$ingredientList

Retorne um JSON com o formato:
{
  "recipes": [
    {
      "name": "nome da receita",
      "description": "breve descrição",
      "difficulty": "fácil | médio | difícil",
      "duration": "tempo estimado (ex: 25 minutos)",
      "ingredients": ["ingrediente 1", "ingrediente 2"],
      "steps": ["passo 1", "passo 2"]
    }
  ]
}

Para cada receita escolha uma dificuldade coerente (fácil, médio ou difícil) considerando o preparo e indique o tempo total aproximado em minutos. Certifique-se de que cada receita use somente os ingredientes informados (além dos genéricos permitidos).''';
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
}
