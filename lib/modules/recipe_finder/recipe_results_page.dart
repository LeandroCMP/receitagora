import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'recipe_detail_page.dart';
import 'widgets/empty_recipes_view.dart';
import 'widgets/recipe_card.dart';

class RecipeResultsArgs {
  RecipeResultsArgs({
    required List<RecipeEntity> recipes,
    required List<String> ingredients,
    this.message,
  })  : recipes = List<RecipeEntity>.unmodifiable(recipes),
        ingredients = List<String>.unmodifiable(ingredients);

  final List<RecipeEntity> recipes;
  final List<String> ingredients;
  final String? message;
}

class RecipeResultsPage extends StatelessWidget {
  const RecipeResultsPage({super.key});

  RecipeResultsArgs _resolveArgs() {
    final dynamic rawArgs = Get.arguments;
    if (rawArgs is RecipeResultsArgs) {
      return rawArgs;
    }

    return RecipeResultsArgs(
      recipes: const [],
      ingredients: const [],
      message: 'Não foi possível carregar as receitas desta vez.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = _resolveArgs();
    final sessionService = Get.find<SessionService>();
    final favoritesService = Get.find<RecipeFavoritesService>();

    Future<void> toggleFavorite(RecipeEntity recipe) async {
      if (!sessionService.isAuthenticated) {
        AppSnackbar.info(
          title: 'Faça login',
          message:
              'Entre com sua conta para salvar e organizar suas receitas preferidas.',
        );
        return;
      }

      final alreadyFavorite = favoritesService.isFavoriteSync(recipe);

      try {
        await favoritesService.toggleFavorite(recipe);
        AppSnackbar.info(
          title: alreadyFavorite ? 'Favorito removido' : 'Favorito salvo',
          message: alreadyFavorite
              ? 'Esta receita saiu da sua coleção.'
              : 'Você encontra a receita em "Favoritos".',
        );
      } on FavoritesFailure catch (error) {
        AppSnackbar.error(
          title: 'Algo deu errado',
          message: error.message,
        );
      } catch (_) {
        AppSnackbar.error(
          title: 'Algo deu errado',
          message:
              'Não foi possível atualizar seus favoritos agora. Tente novamente.',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sugestões para hoje',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (!sessionService.isAuthenticated) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Ver favoritos',
              icon: const Icon(Icons.favorite_rounded),
              onPressed: () => Get.toNamed(AppRoutes.favorites),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton(
              onPressed: () => Get.offAllNamed(AppRoutes.recipeFinder),
              child: const Text('Nova busca'),
            ),
          ),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 780,
                topPadding: 32,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: SingleChildScrollView(
                  padding: layout.padding,
                  physics: const BouncingScrollPhysics(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: layout.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ResultsSummaryCard(theme: theme, args: args),
                          if (args.message != null) ...[
                            const SizedBox(height: 20),
                            _InfoBanner(message: args.message!),
                          ],
                          const SizedBox(height: 28),
                          if (args.recipes.isEmpty)
                            EmptyRecipesView(
                              message: args.message ??
                                  'Não encontramos receitas com esses ingredientes. Ajuste a combinação e tente novamente.',
                            )
                          else
                            StreamBuilder<UserMode?>(
                              stream: sessionService.modeStream,
                              initialData: sessionService.mode,
                              builder: (context, modeSnapshot) {
                                final isAuthenticated =
                                    modeSnapshot.data == UserMode.authenticated;

                                return StreamBuilder<Set<String>>(
                                  stream: favoritesService.favoriteIdsStream,
                                  initialData: favoritesService.favoriteIds,
                                  builder: (context, snapshot) {
                                    final favoriteIds = snapshot.data ??
                                        favoritesService.favoriteIds;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: List.generate(
                                        args.recipes.length,
                                        (index) {
                                          final recipe = args.recipes[index];
                                          final heroTag =
                                              'recipe-${recipe.name.hashCode}-$index';
                                          final isFavorite = favoriteIds.contains(
                                            favoritesService.favoriteIdFor(recipe),
                                          );

                                          return RecipeSummaryCard(
                                            recipe: recipe,
                                            position: index,
                                            heroTag: heroTag,
                                            onTap: () {
                                              Get.to(
                                                () => RecipeDetailPage(
                                                  recipe: recipe,
                                                  heroTag: heroTag,
                                                ),
                                                transition: Transition.cupertino,
                                              );
                                            },
                                            action: IconButton(
                                              tooltip: !isAuthenticated
                                                  ? 'Disponível após login'
                                                  : isFavorite
                                                      ? 'Remover dos favoritos'
                                                      : 'Salvar nos favoritos',
                                              icon: Icon(
                                                isFavorite
                                                    ? Icons.favorite_rounded
                                                    : Icons.favorite_outline,
                                                color: isAuthenticated && isFavorite
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurface
                                                        .withValues(alpha: 
                                                            isAuthenticated ? 0.6 : 0.35),
                                              ),
                                              onPressed: () => toggleFavorite(recipe),
                                            ),
                                            footer: isAuthenticated
                                                ? null
                                                : _GuestFooter(theme: theme),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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

class _ResultsSummaryCard extends StatelessWidget {
  const _ResultsSummaryCard({required this.theme, required this.args});

  final ThemeData theme;
  final RecipeResultsArgs args;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.26),
        (surfaces?.low ?? theme.colorScheme.primaryContainer)
            .withValues(alpha: 0.85),
      ],
    );

    final foregroundColor = theme.colorScheme.onPrimaryContainer;
    final shadowColor = theme.colorScheme.primary.withValues(alpha: 0.16);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    border: Border.all(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: foregroundColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${args.recipes.length} sugestões preparadas',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Receitas alinhadas aos ingredientes escolhidos para hoje.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.72),
                          height: 1.42,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Divider(
              height: 1,
              color: foregroundColor.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 22),
            if (args.ingredients.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Nenhum ingrediente informado nesta busca.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor.withValues(alpha: 0.78),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingredientes utilizados',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: args.ingredients
                        .map(
                          (ingredient) => _IngredientPill(
                            ingredient: ingredient,
                            theme: theme,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientPill extends StatelessWidget {
  const _IngredientPill({required this.ingredient, required this.theme});

  final String ingredient;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = theme.colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_grocery_store_outlined,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
          Text(
            ingredient,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (surfaces?.high ?? theme.colorScheme.surfaceVariant).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestFooter extends StatelessWidget {
  const _GuestFooter({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Crie uma conta para favoritar e acompanhar suas receitas preferidas.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}
