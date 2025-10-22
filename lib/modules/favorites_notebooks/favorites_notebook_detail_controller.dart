import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/favorites/favorited_recipe_entity.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';

class FavoritesNotebookDetailArgs {
  const FavoritesNotebookDetailArgs({required this.notebookId});

  final String notebookId;
}

class FavoritesNotebookDetailController extends GetxController {
  FavoritesNotebookDetailController({
    required this.args,
    required this.notebookService,
    required this.favoritesService,
  });

  final FavoritesNotebookDetailArgs args;
  final FavoritesNotebookService notebookService;
  final RecipeFavoritesService favoritesService;

  final Rxn<FavoritesNotebook> notebook = Rxn<FavoritesNotebook>();
  final RxList<FavoritedRecipeEntity> favorites = <FavoritedRecipeEntity>[].obs;
  final RxBool isProcessing = false.obs;

  StreamSubscription<List<FavoritesNotebook>>? _notebookSubscription;
  StreamSubscription<List<FavoritedRecipeEntity>>? _favoritesSubscription;

  @override
  void onInit() {
    super.onInit();
    _notebookSubscription = notebookService.notebooksStream.listen((items) {
      notebook.value = items.firstWhereOrNull(
        (item) => item.id == args.notebookId,
      );
    });
    notebook.value = notebookService.notebooks.firstWhereOrNull(
      (item) => item.id == args.notebookId,
    );

    favorites.assignAll(favoritesService.favorites);
    _favoritesSubscription = favoritesService.favoritesStream.listen(
      favorites.assignAll,
    );
  }

  @override
  void onClose() {
    _notebookSubscription?.cancel();
    _favoritesSubscription?.cancel();
    super.onClose();
  }

  bool containsFavorite(String favoriteId) {
    final current = notebook.value;
    if (current == null) {
      return false;
    }
    return current.favoriteIds.contains(favoriteId);
  }

  Future<void> toggleFavorite(FavoritedRecipeEntity favorite, bool add) async {
    try {
      if (add) {
        await notebookService.addFavorite(
          notebookId: args.notebookId,
          favorite: favorite,
        );
      } else {
        await notebookService.removeFavorite(
          notebookId: args.notebookId,
          favoriteId: favorite.id,
        );
      }
    } catch (error) {
      AppSnackbar.error(
        title: 'Não foi possível atualizar o caderno',
        message: 'Verifique a conexão e tente novamente.',
      );
    }
  }

  Future<void> addComment(String message) async {
    try {
      await notebookService.addComment(
        notebookId: args.notebookId,
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível enviar o comentário',
        message: 'Tente novamente em alguns instantes.',
      );
    }
  }

  Future<void> toggleCollaboration(bool enable) async {
    final currentNotebook = notebook.value;
    if (currentNotebook == null) {
      return;
    }
    if (!currentNotebook.isOwner) {
      AppSnackbar.info(
        title: 'Ação restrita',
        message: 'Somente o criador pode alterar o modo colaborativo.',
      );
      return;
    }
    if (isProcessing.value) {
      return;
    }
    isProcessing.value = true;
    try {
      await notebookService.updateNotebook(
        notebookId: args.notebookId,
        collaborative: enable,
      );
      AppSnackbar.success(
        title: enable ? 'Modo colaborativo ativado' : 'Modo colaborativo desligado',
        message: enable
            ? 'Compartilhe o código para convidar outras pessoas.'
            : 'Apenas você poderá editar este caderno.',
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível atualizar o caderno',
        message: 'Tente novamente em alguns instantes.',
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<String?> ensureShareCode() async {
    final currentNotebook = notebook.value;
    if (currentNotebook == null) {
      return null;
    }
    if (!currentNotebook.isOwner) {
      if (currentNotebook.shareCode != null &&
          currentNotebook.shareCode!.isNotEmpty) {
        return currentNotebook.shareCode;
      }
      AppSnackbar.info(
        title: 'Convite indisponível',
        message: 'Somente o criador pode gerar o código de colaboração.',
      );
      return null;
    }
    try {
      final code = await notebookService.ensureShareCode(args.notebookId);
      if (code == null) {
        AppSnackbar.error(
          title: 'Código indisponível',
          message: 'Ative a colaboração para gerar um código de convite.',
        );
      }
      return code;
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível gerar o código',
        message: 'Tente novamente em instantes.',
      );
      return null;
    }
  }

  Future<String?> exportNotebook() async {
    try {
      return await notebookService.exportNotebook(
        args.notebookId,
        favoritesById: {
          for (final favorite in favorites) favorite.id: favorite,
        },
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Não foi possível preparar o conteúdo',
        message: 'Tente novamente em instantes.',
      );
      return null;
    }
  }

  FavoritesNotebook? get current => notebook.value;
}
