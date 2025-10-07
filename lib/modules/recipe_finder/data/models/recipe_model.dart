import '../../domain/entities/recipe_entity.dart';

class RecipeModel extends RecipeEntity {
  const RecipeModel({
    required super.name,
    required super.description,
    required super.ingredients,
    required super.steps,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      name: map['name'] as String? ?? 'Receita sem nome',
      description: map['description'] as String? ?? 'Descrição indisponível.',
      ingredients: (map['ingredients'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      steps: (map['steps'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'steps': steps,
      };
}
