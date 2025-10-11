import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
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
      Get.snackbar(
        'Remoção cancelada',
        'A receita continuará disponível nos seus favoritos.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      await favoritesService.removeFavoriteById(favorite.id);
      Get.snackbar(
        'Favorito removido',
        'Esta receita saiu da sua lista. Você pode adicioná-la novamente quando desejar.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on FavoritesFailure catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Não foi possível atualizar seus favoritos agora. Tente novamente.');
    }
  }

  void openFavoritesOnLoginRequirement() {
    Get.offAllNamed(AppRoutes.login);
    Get.snackbar(
      'Faça login',
      'Entre com sua conta para acessar suas receitas favoritas.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Algo deu errado',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Get.theme.colorScheme.errorContainer.withOpacity(0.95),
      colorText: Get.theme.colorScheme.onErrorContainer,
    );
  }
}
