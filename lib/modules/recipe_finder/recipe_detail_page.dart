import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';
import 'package:receitagora/services/share/recipe_share_service.dart';

import 'widgets/recipe_cover.dart';

class RecipeDetailArgs {
  const RecipeDetailArgs({
    required this.recipe,
    required this.heroTag,
    this.position = 0,
  });

  final RecipeEntity recipe;
  final String heroTag;
  final int position;
}

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({
    super.key,
    this.recipe,
    this.heroTag,
    this.position,
  });

  final RecipeEntity? recipe;
  final String? heroTag;
  final int? position;

  RecipeDetailArgs _resolveArgs() {
    if (recipe != null && heroTag != null) {
      return RecipeDetailArgs(
        recipe: recipe!,
        heroTag: heroTag!,
        position: position ?? 0,
      );
    }

    final dynamic rawArgs = Get.arguments;
    if (rawArgs is RecipeDetailArgs) {
      return rawArgs;
    }

    return RecipeDetailArgs(
      recipe: const RecipeEntity(
        name: 'Receita',
        description: 'Não foi possível carregar os detalhes desta receita.',
        ingredients: [],
        steps: [],
        difficulty: 'Dificuldade desconhecida',
        duration: 'Tempo indisponível',
      ),
      heroTag: 'recipe-fallback',
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArgs();
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final sessionService = Get.find<SessionService>();
    final favoritesService = Get.find<RecipeFavoritesService>();
    final shareService = Get.find<RecipeShareService>();

    void showFavoriteError(String message) {
      Get.snackbar(
        'Algo deu errado',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.95),
        colorText: theme.colorScheme.onErrorContainer,
      );
    }

    Future<void> toggleFavorite() async {
      if (!sessionService.isAuthenticated) {
        Get.snackbar(
          'Faça login',
          'Entre com sua conta para salvar receitas favoritas.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final recipe = args.recipe;
      final alreadyFavorite = favoritesService.isFavoriteSync(recipe);

      try {
        await favoritesService.toggleFavorite(recipe);
        Get.snackbar(
          alreadyFavorite ? 'Favorito removido' : 'Adicionado aos favoritos',
          alreadyFavorite
              ? 'Esta receita foi removida da sua lista.'
              : 'Ela agora aparece na tela de favoritos.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } on FavoritesFailure catch (error) {
        showFavoriteError(error.message);
      } catch (_) {
        showFavoriteError('Não foi possível atualizar seus favoritos agora.');
      }
    }

    Future<void> shareRecipe() async {
      var overlayShown = false;
      if (!(Get.isDialogOpen ?? false)) {
        overlayShown = true;
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }

      void closeOverlay() {
        if (overlayShown && (Get.isDialogOpen ?? false)) {
          Get.back();
          overlayShown = false;
        }
      }

      void showShareError(String message) {
        Get.snackbar(
          'Não foi possível compartilhar',
          message,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.95),
          colorText: theme.colorScheme.onErrorContainer,
        );
      }

      try {
        await shareService.shareRecipe(args.recipe);
      } on ShareFailure catch (error) {
        closeOverlay();
        showShareError(error.message);
        return;
      } catch (_) {
        closeOverlay();
        showShareError('Tente novamente em instantes.');
        return;
      }

      closeOverlay();
      Get.snackbar(
        'Pronto para compartilhar',
        'Escolha o aplicativo desejado para enviar esta receita deliciosa.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(args.recipe.name),
        actions: [
          IconButton(
            tooltip: 'Compartilhar receita',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: shareRecipe,
          ),
          Obx(() {
            if (!sessionService.isAuthenticated) {
              return const SizedBox.shrink();
            }

            return StreamBuilder<Set<String>>(
              stream: favoritesService.favoriteIdsStream,
              initialData: favoritesService.favoriteIds,
              builder: (context, snapshot) {
                final favoriteIds =
                    snapshot.data ?? favoritesService.favoriteIds;
                final isFavorite = favoriteIds.contains(
                  favoritesService.favoriteIdFor(args.recipe),
                );

                return IconButton(
                  tooltip: isFavorite
                      ? 'Remover dos favoritos'
                      : 'Salvar nos favoritos',
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: isFavorite ? theme.colorScheme.primary : null,
                  ),
                  onPressed: toggleFavorite,
                );
              },
            );
          }),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.05),
                surfaces?.lowest ?? background,
              ),
              background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 760,
                topPadding: 36,
              );

              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: layout.padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _OverviewSection(args: args),
                        ),
                        if (args.recipe.ingredients.isNotEmpty) ...[
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          SliverToBoxAdapter(
                            child: _IngredientsSection(recipe: args.recipe),
                          ),
                        ],
                        if (args.recipe.steps.isNotEmpty) ...[
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          SliverToBoxAdapter(
                            child: _StepsSection(recipe: args.recipe),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.args});

  final RecipeDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = args.recipe;
    final description = recipe.description.trim();
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 560;
            final gap = isCompact ? 24.0 : 32.0;

            final cover = RecipeCover(
              theme: theme,
              recipe: recipe,
              position: args.position,
              heroTag: args.heroTag,
              size: isCompact ? 140 : 170,
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                          .withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    recipe.difficulty,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  recipe.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OverviewPill(
                      icon: Icons.schedule_rounded,
                      label: recipe.duration,
                      accent: theme.colorScheme.secondary,
                    ),
                    _OverviewPill(
                      icon: Icons.restaurant_menu,
                      label:
                          '${recipe.ingredients.length} ingrediente${recipe.ingredients.length == 1 ? '' : 's'}',
                      accent: theme.colorScheme.primary,
                    ),
                    _OverviewPill(
                      icon: Icons.auto_awesome,
                      label: recipe.difficulty,
                      accent: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                      height: 1.55,
                    ),
                  ),
                ],
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cover,
                  SizedBox(height: gap),
                  content,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: content),
                SizedBox(width: gap),
                cover,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
              .withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({required this.recipe});

  final RecipeEntity recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredientes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ...recipe.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: theme.colorScheme.onSurface.withOpacity(0.78),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.recipe});

  final RecipeEntity recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modo de preparo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(recipe.steps.length, (index) {
              final step = recipe.steps[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == recipe.steps.length - 1 ? 0 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                                  .withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: theme.colorScheme.onSurface.withOpacity(0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
