import 'package:equatable/equatable.dart';

class RecipeEntity extends Equatable {
  const RecipeEntity({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.difficulty,
    required this.duration,
  });

  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String difficulty;
  final String duration;

  @override
  List<Object?> get props => [
        name,
        description,
        ingredients,
        steps,
        difficulty,
        duration,
      ];
}
