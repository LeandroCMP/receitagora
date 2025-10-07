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
    final apiKey = dotenv.maybeGet('OPENAI_API_KEY') ?? '';
    final baseUrl = dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1';
    final model = dotenv.maybeGet('OPENAI_MODEL') ?? 'gpt-4o-mini';

    return EnvironmentConfig(
      openAIApiKey: apiKey,
      openAIBaseUrl: baseUrl,
      model: model,
    );
  }

  bool get hasValidCredentials => openAIApiKey.isNotEmpty;
}
