import 'package:equatable/equatable.dart';

import '../../../recipe_finder/domain/entities/recipe_entity.dart';

class FavoritedRecipeEntity extends Equatable {
  const FavoritedRecipeEntity({
    required this.id,
    required this.recipe,
    this.favoritedAt,
  });

  final String id;
  final RecipeEntity recipe;
  final DateTime? favoritedAt;

  @override
  List<Object?> get props => [id, recipe, favoritedAt];
}
