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
    if (!config.hasValidCredentials) {
      throw const AppException(
        'Configure sua chave da OpenAI para gerar receitas com a IA.',
      );
    }

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

    try {
      final response =
          await _postWithRetry(uri, headers: headers, body: payload);
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
          throw const AppException('Resposta vazia da OpenAI');
        }
        final message = choices.first['message'] as Map<String, dynamic>?
            ?? (throw const AppException('Formato inesperado da OpenAI'));
        final content = _readMessageContent(message['content']);
        if (content == null || content.trim().isEmpty) {
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
}
