import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/modules/recipe_finder/widgets/recipe_card.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'favorited_recipe_entity.dart';
import 'favorites_controller.dart';

class FavoritesPage extends GetView<FavoritesController> {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final sessionService = Get.find<SessionService>();
    final favoritesService = Get.find<RecipeFavoritesService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          TextButton(
            onPressed: () => Get.offAllNamed(AppRoutes.recipeFinder),
            child: const Text('Buscar receitas'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.05),
                surfaces?.lowest ?? background,
              ),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 760,
                topPadding: 32,
                bottomPadding: 24,
              );

              return Obx(() {
                if (!sessionService.isAuthenticated) {
                  return _GuestNotice(theme: theme, controller: controller);
                }

                final favorites = favoritesService.favorites.toList();
                if (favorites.isEmpty) {
                  return _EmptyFavorites(theme: theme, layout: layout);
                }

                return SingleChildScrollView(
                  padding: layout.padding,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FavoritesHeader(theme: theme, favorites: favorites),
                          const SizedBox(height: 24),
                          ...List.generate(
                            favorites.length,
                            (index) {
                              final favorite = favorites[index];
                              return _FavoriteRecipeCard(
                                controller: controller,
                                favorite: favorite,
                                index: index,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({
    required this.theme,
    required this.favorites,
  });

  final ThemeData theme;
  final List<FavoritedRecipeEntity> favorites;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suas receitas favoritas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              favorites.length == 1
                  ? 'Você tem 1 receita salva para revisitar quando quiser.'
                  : 'Você tem ${favorites.length} receitas salvas. Toque em uma delas para ver os detalhes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                      .withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remova com cuidado: a receita some da lista imediatamente.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRecipeCard extends StatelessWidget {
  const _FavoriteRecipeCard({
    required this.controller,
    required this.favorite,
    required this.index,
  });

  final FavoritesController controller;
  final FavoritedRecipeEntity favorite;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = favorite.recipe;
    return RecipeSummaryCard(
      recipe: recipe,
      position: index,
      heroTag: 'favorite-${favorite.id}',
      onTap: () => controller.openFavorite(favorite, index),
      action: Tooltip(
        message: 'Remover dos favoritos',
        child: IconButton(
          icon: Icon(
            Icons.favorite,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => controller.confirmRemoval(favorite),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.theme,
    required this.layout,
  });

  final ThemeData theme;
  final AppPageLayoutValues layout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: layout.padding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 32, 26, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma receita favorita por aqui',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Busque receitas e toque no ícone de coração para salvar suas preferidas. '
                    'Elas aparecerão aqui para você acessar mais tarde.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => Get.offAllNamed(AppRoutes.recipeFinder),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Descobrir receitas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice({
    required this.theme,
    required this.controller,
  });

  final ThemeData theme;
  final FavoritesController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entre para salvar favoritos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'As receitas favoritas ficam vinculadas à sua conta. Faça login para visualizar ou gerenciar sua lista.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: controller.openFavoritesOnLoginRequirement,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Fazer login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
