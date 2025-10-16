import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/recipe_finder/recipe_detail_page.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'favorited_recipe_entity.dart';

class FavoritesController extends GetxController {
  FavoritesController({
    required this.sessionService,
    required this.favoritesService,
  });

  final SessionService sessionService;
  final RecipeFavoritesService favoritesService;

  bool get isAuthenticated => sessionService.isAuthenticated;

  Future<void> openFavorite(FavoritedRecipeEntity favorite, int index) async {
    await Get.to(
      () => RecipeDetailPage(
        recipe: favorite.recipe,
        heroTag: 'favorite-${favorite.id}',
        position: index,
      ),
      transition: Transition.cupertino,
    );
  }

  Future<void> confirmRemoval(FavoritedRecipeEntity favorite) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remover dos favoritos?'),
        content: const Text(
          'Ao remover, esta receita deixará de aparecer na sua lista de favoritos. '
          'Você poderá adicioná-la novamente quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remover'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) {
      AppSnackbar.info(
        title: 'Remoção cancelada',
        message: 'A receita continuará disponível nos seus favoritos.',
      );
      return;
    }

    try {
      await favoritesService.removeFavoriteById(favorite.id);
      AppSnackbar.info(
        title: 'Favorito removido',
        message: 'Esta receita saiu da sua lista. Você pode adicioná-la novamente quando desejar.',
      );
    } on FavoritesFailure catch (error) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Não foi possível atualizar seus favoritos agora. Tente novamente.',
      );
    }
  }

  void openFavoritesOnLoginRequirement() {
    Get.offAllNamed(AppRoutes.login);
    AppSnackbar.info(
      title: 'Faça login',
      message: 'Entre com sua conta para acessar suas receitas favoritas.',
    );
  }
}
