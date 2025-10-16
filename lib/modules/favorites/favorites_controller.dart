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
  final selectedTag = RxnString();

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

  List<FavoritedRecipeEntity> applyTagFilter(
    List<FavoritedRecipeEntity> favorites,
  ) {
    final tag = selectedTag.value;
    if (tag == null) {
      return favorites;
    }
    return favorites.where((favorite) => favorite.tags.contains(tag)).toList();
  }

  void toggleTagFilter(String tag) {
    if (selectedTag.value == tag) {
      selectedTag.value = null;
    } else {
      selectedTag.value = tag;
    }
  }

  void clearTagFilter() {
    selectedTag.value = null;
  }

  Future<void> applyTags(
    FavoritedRecipeEntity favorite,
    List<String> tags,
  ) async {
    final unique = <String>{};
    final sanitized = <String>[];
    for (final tag in tags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (unique.add(key)) {
        sanitized.add(trimmed);
      }
    }
    sanitized.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (sanitized.isEmpty) {
      await favoritesService.updateTags(favoriteId: favorite.id, tags: const <String>[]);
      AppSnackbar.info(
        title: 'Tags removidas',
        message: 'Esta receita não possui mais categorias associadas.',
      );
      return;
    }

    if (sanitized.length > RecipeFavoritesService.maxTagsPerRecipe) {
      AppSnackbar.info(
        title: 'Limite de tags',
        message:
            'Use no máximo ${RecipeFavoritesService.maxTagsPerRecipe} tags por receita para manter a organização.',
      );
      return;
    }

    try {
      await favoritesService.updateTags(
        favoriteId: favorite.id,
        tags: sanitized,
      );
      AppSnackbar.success(
        title: 'Tags atualizadas',
        message: 'As categorias desta receita foram sincronizadas.',
      );
    } on FavoritesFailure catch (error) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: error.message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Não foi possível atualizar as tags agora. Tente novamente.',
      );
    }
  }
}
