import 'package:receitagora/core/errors/app_exception.dart';
import 'package:receitagora/modules/recipe_finder/data/datasources/recipe_remote_data_source.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/modules/recipe_finder/domain/repositories/recipe_repository.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl({required this.remoteDataSource});

  final RecipeRemoteDataSource remoteDataSource;

  @override
  Future<List<RecipeEntity>> generateRecipes(List<String> ingredients) async {
    try {
      return await remoteDataSource.generateRecipes(ingredients);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException('Erro inesperado ao gerar receitas', details: error.toString());
    }
  }
}
