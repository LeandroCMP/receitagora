import 'dart:async';

import 'package:get/get.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';

class FavoritesNotebooksController extends GetxController {
  FavoritesNotebooksController({
    required this.notebookService,
    required this.favoritesService,
  });

  final FavoritesNotebookService notebookService;
  final RecipeFavoritesService favoritesService;

  final RxList<FavoritesNotebook> notebooks = <FavoritesNotebook>[].obs;
  final RxMap<String, FavoritedRecipeEntity> favoritesById =
      <String, FavoritedRecipeEntity>{}.obs;
  final RxBool isCreating = false.obs;
  final RxBool isJoining = false.obs;

  StreamSubscription<List<FavoritesNotebook>>? _notebookSubscription;
  StreamSubscription<List<FavoritedRecipeEntity>>? _favoritesSubscription;

  @override
  void onInit() {
    super.onInit();
    notebooks.assignAll(notebookService.notebooks);
    favoritesById.assignAll({
      for (final favorite in favoritesService.favorites) favorite.id: favorite,
    });

    _notebookSubscription = notebookService.notebooksStream.listen(
      notebooks.assignAll,
    );
    _favoritesSubscription = favoritesService.favoritesStream.listen((items) {
      favoritesById.assignAll({
        for (final item in items) item.id: item,
      });
    });
  }

  @override
  void onClose() {
    _notebookSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  Future<void> createNotebook({
    required String title,
    String? description,
    bool collaborative = false,
  }) async {
    if (isCreating.value) {
      return;
    }
    isCreating.value = true;
    try {
      await notebookService.createNotebook(
        title: title,
        description: description,
        collaborative: collaborative,
      );
      AppSnackbar.success(
        title: 'Caderno criado',
        message: collaborative
            ? 'Compartilhe o código para colaborar com outras pessoas.'
            : 'Adicione receitas favoritas para organizar suas coleções.',
      );
    } catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível criar o caderno',
        message: 'Tente novamente em alguns instantes.',
      );
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> joinByShareCode(String code) async {
    if (isJoining.value) {
      return;
    }
    isJoining.value = true;
    try {
      await notebookService.joinByShareCode(code.toUpperCase());
      AppSnackbar.success(
        title: 'Convite aceito',
        message: 'O caderno colaborativo foi adicionado à sua lista.',
      );
    } catch (error) {
      AppSnackbar.error(
        title: 'Código inválido',
        message: 'Verifique o código informado e tente novamente.',
      );
    } finally {
      isJoining.value = false;
    }
  }

  Future<String?> exportNotebook(FavoritesNotebook notebook) async {
    final favorites = favoritesById.map((key, value) => MapEntry(key, value));
    return notebookService.exportNotebook(
      notebook.id,
      favoritesById: favorites,
    );
  }

  Future<String?> ensureShareCodeFor(FavoritesNotebook notebook) async {
    if (!notebook.isOwner) {
      if (notebook.shareCode != null && notebook.shareCode!.isNotEmpty) {
        return notebook.shareCode;
      }
      AppSnackbar.info(
        title: 'Convite indisponível',
        message: 'Somente o criador do caderno pode gerar um código.',
      );
      return null;
    }
    try {
      return await notebookService.ensureShareCode(notebook.id);
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível gerar o código',
        message: 'Tente novamente em instantes.',
      );
      return null;
    }
  }
}
