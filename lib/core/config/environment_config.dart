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
    final apiKey = "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";
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
