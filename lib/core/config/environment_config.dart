import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.openAIApiKey,
    required this.openAIBaseUrl,
    required this.model,
  });

  final String openAIApiKey;
  final String openAIBaseUrl;
  final String model;

  factory EnvironmentConfig.fromEnv() {
    final apiKey = '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'; //(dotenv.maybeGet('OPENAI_API_KEY') ?? '').trim();
    final baseUrl =
        (dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1')
            .trim();
    final model = (dotenv.maybeGet('OPENAI_MODEL') ?? 'gpt-4o-mini').trim();

    return EnvironmentConfig(
      openAIApiKey: apiKey,
      openAIBaseUrl: baseUrl,
      model: model,
    );
  }

  bool get hasValidCredentials => openAIApiKey.trim().isNotEmpty;
}
