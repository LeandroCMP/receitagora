import 'package:flutter/foundation.dart';

@immutable
class IngredientLabAlternative {
  const IngredientLabAlternative({
    required this.name,
    required this.description,
    required this.ratio,
    required this.adjustments,
    required this.idealUses,
    required this.cautions,
  });

  final String name;
  final String description;
  final String ratio;
  final List<String> adjustments;
  final List<String> idealUses;
  final List<String> cautions;

  factory IngredientLabAlternative.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const IngredientLabAlternative(
        name: 'Alternativa desconhecida',
        description:
            'A IA não conseguiu fornecer detalhes completos desta substituição.',
        ratio: '1:1',
        adjustments: <String>[],
        idealUses: <String>[],
        cautions: <String>[],
      );
    }

    return IngredientLabAlternative(
      name: _readString(map['name']) ?? 'Alternativa sem nome',
      description:
          _readString(map['description']) ?? 'Sem descrição fornecida pela IA.',
      ratio: _readString(map['ratio']) ?? '1:1',
      adjustments: _readStringList(map['adjustments']),
      idealUses: _readStringList(map['idealUses']),
      cautions: _readStringList(map['cautions']),
    );
  }
}

@immutable
class IngredientLabReport {
  const IngredientLabReport({
    required this.ingredient,
    required this.roleSummary,
    required this.highlights,
    required this.alternatives,
    required this.techniqueTips,
    required this.warnings,
    required this.shoppingSuggestions,
  });

  final String ingredient;
  final String roleSummary;
  final List<String> highlights;
  final List<IngredientLabAlternative> alternatives;
  final List<String> techniqueTips;
  final List<String> warnings;
  final List<String> shoppingSuggestions;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasShoppingSuggestions => shoppingSuggestions.isNotEmpty;

  factory IngredientLabReport.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const IngredientLabReport(
        ingredient: 'Ingrediente desconhecido',
        roleSummary:
            'Não foi possível gerar o relatório do laboratório com os dados fornecidos.',
        highlights: <String>[],
        alternatives: <IngredientLabAlternative>[],
        techniqueTips: <String>[],
        warnings: <String>[],
        shoppingSuggestions: <String>[],
      );
    }

    final rawAlternatives = map['recommendedAlternatives'];
    final alternatives = rawAlternatives is Iterable
        ? rawAlternatives
            .map((dynamic item) =>
                IngredientLabAlternative.fromMap(item as Map<String, dynamic>?))
            .toList()
        : <IngredientLabAlternative>[];

    return IngredientLabReport(
      ingredient: _readString(map['ingredient']) ?? 'Ingrediente alvo',
      roleSummary:
          _readString(map['roleSummary']) ?? 'Resumo não informado pela IA.',
      highlights: _readStringList(map['highlights']),
      alternatives: List<IngredientLabAlternative>.unmodifiable(alternatives),
      techniqueTips: _readStringList(map['techniqueTips']),
      warnings: _readStringList(map['warnings']),
      shoppingSuggestions: _readStringList(map['shoppingSuggestions']),
    );
  }
}

String? _readString(dynamic value) {
  if (value is String) {
    final sanitized = value.trim();
    return sanitized.isEmpty ? null : sanitized;
  }
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is Iterable) {
    final list = value
        .map((dynamic item) => item?.toString())
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(list);
  }
  return const <String>[];
}
