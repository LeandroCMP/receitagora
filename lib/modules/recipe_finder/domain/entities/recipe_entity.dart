import 'package:equatable/equatable.dart';

class RecipeEntity extends Equatable {
  const RecipeEntity({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
  });

  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;

  @override
  List<Object?> get props => [name, description, ingredients, steps];
}
