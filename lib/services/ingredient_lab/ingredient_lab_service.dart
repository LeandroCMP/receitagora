import 'package:get/get.dart';

import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/models/ingredient_lab/ingredient_lab_report.dart';
import 'package:receitagora/models/ingredient_lab/ingredient_lab_request.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/openai/openai_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class IngredientLabService extends GetxService {
  IngredientLabService({
    required this.openAIService,
    required this.sessionService,
  });

  final OpenAIService openAIService;
  final SessionService sessionService;

  Future<IngredientLabReport> runLaboratory(IngredientLabRequest request) async {
    await sessionService.ensureInitialized();
    if (!sessionService.hasPremiumAccess) {
      throw const AppException(
        'Este recurso faz parte do plano Premium. Faça upgrade para acessar o laboratório de ingredientes.',
      );
    }

    final user = sessionService.user;
    final allergies = _mergeAllergies(request.restrictions, user);

    final systemPrompt =
        'Você é o Chef IA do Laboratório de Ingredientes do Receitagora. Sempre responda em português brasileiro com um JSON seguindo rigorosamente o schema solicitado, oferecendo substituições culinárias confiáveis e contextualizadas para o ingrediente alvo.';

    final promptBuffer = StringBuffer()
      ..writeln('Ingrediente principal: ${request.ingredient}.');

    if (request.dishContext != null) {
      promptBuffer.writeln('Contexto da receita: ${request.dishContext}.');
    }
    if (request.hasAvailableIngredients) {
      promptBuffer.writeln(
        'Ingredientes disponíveis para experimentar substituições: ${request.availableIngredients.join(', ')}.',
      );
    }
    if (allergies.isNotEmpty) {
      promptBuffer.writeln('Restrinja opções que possam conter: ${allergies.join(', ')}.');
    }
    if (request.desiredOutcome != null) {
      promptBuffer.writeln('Objetivo da substituição: ${request.desiredOutcome}.');
    }
    if (request.notes != null) {
      promptBuffer.writeln('Observações extras do usuário: ${request.notes}.');
    }
    if (user != null) {
      promptBuffer.writeln('Bio do usuário: ${user.bio ?? 'não informada'}');
      if (user.dietaryPreferences.isNotEmpty) {
        promptBuffer.writeln(
          'Preferências alimentares declaradas: ${user.dietaryPreferences.join(', ')}.',
        );
      }
    }

    promptBuffer.writeln('Retorne um JSON com as chaves:');
    promptBuffer.writeln('ingredient (string), roleSummary (string), highlights (array de strings),');
    promptBuffer.writeln(
      'recommendedAlternatives (array de objetos com name, description, ratio, adjustments (array de strings), idealUses (array de strings) e cautions (array de strings)),',
    );
    promptBuffer.writeln(
        'techniqueTips (array de strings), warnings (array de strings), shoppingSuggestions (array de strings).');
    promptBuffer.writeln('Evite recomendar ingredientes proibidos e utilize medidas práticas do mercado brasileiro.');

    final response = await openAIService.requestStructuredJson(
      systemPrompt: systemPrompt,
      userPrompt: promptBuffer.toString(),
      temperature: 0.65,
    );

    return IngredientLabReport.fromMap(response);
  }

  List<String> _mergeAllergies(List<String> restrictions, UserModel? user) {
    final merged = <String>{
      ...restrictions.map((item) => item.toLowerCase()),
    };
    if (user?.allergies.isNotEmpty == true) {
      merged.addAll(user!.allergies.map((item) => item.toLowerCase()));
    }
    final normalized = merged
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => item[0].toUpperCase() + item.substring(1))
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return normalized;
  }
}
