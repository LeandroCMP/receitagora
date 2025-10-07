import '../../domain/entities/recipe_entity.dart';

class RecipeModel extends RecipeEntity {
  const RecipeModel({
    required super.name,
    required super.description,
    required super.ingredients,
    required super.steps,
    required super.difficulty,
    required super.duration,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    String readField(String key, String fallback) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return fallback;
    }

    return RecipeModel(
      name: readField('name', 'Receita sem nome'),
      description: readField('description', 'Descrição indisponível.'),
      ingredients: (map['ingredients'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      steps: (map['steps'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      difficulty: readField('difficulty', 'Dificuldade não informada'),
      duration: readField('duration', 'Tempo não informado'),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'steps': steps,
        'difficulty': difficulty,
        'duration': duration,
      };
}
