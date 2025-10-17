import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
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

    Future<void> toggleFavorite() async {
      if (!sessionService.isAuthenticated) {
        AppSnackbar.info(
          title: 'Faça login',
          message: 'Entre com sua conta para salvar receitas favoritas.',
        );
        return;
      }

      final recipe = args.recipe;
      final alreadyFavorite = favoritesService.isFavoriteSync(recipe);

      try {
        await favoritesService.toggleFavorite(recipe);
        AppSnackbar.info(
          title: alreadyFavorite ? 'Favorito removido' : 'Adicionado aos favoritos',
          message: alreadyFavorite
              ? 'Esta receita foi removida da sua lista.'
              : 'Ela agora aparece na tela de favoritos.',
        );
      } on FavoritesFailure catch (error) {
        AppSnackbar.error(
          title: 'Algo deu errado',
          message: error.message,
        );
      } catch (_) {
        AppSnackbar.error(
          title: 'Algo deu errado',
          message: 'Não foi possível atualizar seus favoritos agora.',
        );
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

      ShareOutcome outcome;
      try {
        outcome = await shareService.shareRecipe(args.recipe);
      } on ShareFailure catch (error) {
        closeOverlay();
        AppSnackbar.error(
          title: 'Não foi possível compartilhar',
          message: error.message,
        );
        return;
      } catch (_) {
        closeOverlay();
        AppSnackbar.error(
          title: 'Não foi possível compartilhar',
          message: 'Tente novamente em instantes.',
        );
        return;
      }

      closeOverlay();
      switch (outcome) {
        case ShareOutcome.shared:
          AppSnackbar.success(
            title: 'Pronto para compartilhar',
            message:
                'Escolha o aplicativo desejado para enviar esta receita deliciosa.',
          );
          break;
        case ShareOutcome.dismissed:
          AppSnackbar.info(
            title: 'Compartilhamento cancelado',
            message: 'Nenhum aplicativo foi selecionado neste momento.',
          );
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(args.recipe.name),
        actions: [
          StreamBuilder<UserMode?>(
            stream: sessionService.modeStream,
            initialData: sessionService.mode,
            builder: (context, snapshot) {
              final isAuthenticated =
                  snapshot.data == UserMode.authenticated;

              late final Widget shareButton;
              if (!isAuthenticated) {
                shareButton = IconButton(
                  tooltip: 'Disponível após login',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: null,
                );
              } else {
                shareButton = StreamBuilder<int>(
                  stream: sessionService.shareDailyLimitStream,
                  initialData: sessionService.shareDailyLimit,
                  builder: (context, limitSnapshot) {
                    final limit =
                        limitSnapshot.data ?? sessionService.shareDailyLimit;
                    return StreamBuilder<int>(
                      stream: sessionService.shareCountStream,
                      initialData: sessionService.shareCount,
                      builder: (context, shareSnapshot) {
                        final shareCount =
                            shareSnapshot.data ?? sessionService.shareCount;
                        final remaining = limit - shareCount;
                        final canShare = remaining > 0;

                        return IconButton(
                          tooltip: canShare
                              ? 'Compartilhar receita'
                              : 'Limite diário de compartilhamentos atingido',
                          icon: const Icon(Icons.ios_share_rounded),
                          onPressed: canShare ? shareRecipe : null,
                        );
                      },
                    );
                  },
                );
              }

              Widget favoriteButton;
              if (!isAuthenticated) {
                favoriteButton = IconButton(
                  tooltip: 'Faça login para favoritar',
                  onPressed: null,
                  icon: Icon(
                    Icons.favorite_outline,
                    color: theme.disabledColor,
                  ),
                );
              } else {
                favoriteButton = StreamBuilder<Set<String>>(
                  stream: favoritesService.favoriteIdsStream,
                  initialData: favoritesService.favoriteIds,
                  builder: (context, snapshot) {
                    final favoriteIds =
                        snapshot.data ?? favoritesService.favoriteIds;
                    final isFavorite = favoriteIds.contains(
                      favoritesService.favoriteIdFor(args.recipe),
                    );
                    final hasCapacity = isFavorite ||
                        favoriteIds.length <
                            RecipeFavoritesService.maxFavorites;

                    return IconButton(
                      tooltip: isFavorite
                          ? 'Remover dos favoritos'
                          : hasCapacity
                              ? 'Salvar nos favoritos'
                              : 'Limite de favoritos atingido',
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        color:
                            isFavorite ? theme.colorScheme.primary : null,
                      ),
                      onPressed: hasCapacity
                          ? toggleFavorite
                          : () {
                              AppSnackbar.info(
                                title: 'Limite de favoritos',
                                message:
                                    'Salve até ${RecipeFavoritesService.maxFavorites} receitas. Em breve teremos planos para expandir este limite.',
                              );
                            },
                    );
                  },
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  shareButton,
                  favoriteButton,
                ],
              );
            },
          ),
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

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: layout.padding,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: layout.maxContentWidth),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 560;
        final borderRadius = BorderRadius.circular(isCompact ? 28 : 36);
        final coverSize = isCompact ? 150.0 : 200.0;

        final baseSurface = surfaces?.high ?? theme.colorScheme.surface;
        final cardColors = [
          Color.alphaBlend(
            theme.colorScheme.primary.withOpacity(0.08),
            baseSurface,
          ),
          Color.alphaBlend(
            theme.colorScheme.secondary.withOpacity(0.04),
            baseSurface,
          ),
        ];

        final cover = RecipeCover(
          theme: theme,
          recipe: recipe,
          position: args.position,
          heroTag: args.heroTag,
          size: coverSize,
        );

        final highlightLabel = args.position >= 0
            ? 'Receita ${args.position + 1}'
            : null;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlightLabel != null) ...[
              _OverviewBadge(label: highlightLabel),
              const SizedBox(height: 16),
            ],
            Text(
              recipe.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.15,
                fontSize: isCompact ? 26 : 32,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OverviewStatChip(
                  icon: Icons.schedule_rounded,
                  label: recipe.duration,
                ),
                _OverviewStatChip(
                  icon: Icons.restaurant_menu,
                  label:
                      '${recipe.ingredients.length} ingrediente${recipe.ingredients.length == 1 ? '' : 's'}',
                ),
                _OverviewStatChip(
                  icon: Icons.terrain_rounded,
                  label: recipe.difficulty,
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.78),
                  height: 1.55,
                ),
              ),
            ],
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardColors,
            ),
            border: Border.all(
              color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                  .withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 24 : 36,
              isCompact ? 26 : 34,
              isCompact ? 24 : 36,
              isCompact ? 24 : 32,
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: cover,
                      ),
                      const SizedBox(height: 26),
                      content,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 40),
                      cover,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _OverviewStatChip extends StatelessWidget {
  const _OverviewStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewBadge extends StatelessWidget {
  const _OverviewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
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

    return _DetailCard(
      title: 'Ingredientes',
      child: Column(
        children: [
          ...recipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

    return _DetailCard(
      title: 'Modo de preparo',
      child: Column(
        children: [
          ...List.generate(recipe.steps.length, (index) {
            final step = recipe.steps[index];
            final isLast = index == recipe.steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.18),
                          theme.colorScheme.secondary.withOpacity(0.18),
                        ],
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces?.high ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
