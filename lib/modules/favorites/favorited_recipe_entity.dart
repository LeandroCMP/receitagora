import 'package:equatable/equatable.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';

class FavoritedRecipeEntity extends Equatable {
  const FavoritedRecipeEntity({
    required this.id,
    required this.recipe,
    this.favoritedAt,
    this.tags = const <String>[],
  });

  final String id;
  final RecipeEntity recipe;
  final DateTime? favoritedAt;
  final List<String> tags;

  @override
  List<Object?> get props => [id, recipe, favoritedAt, tags];
}
