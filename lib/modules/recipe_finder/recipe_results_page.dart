import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
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
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final args = _resolveArgs();
    final sessionService = Get.find<SessionService>();
    final favoritesService = Get.find<RecipeFavoritesService>();

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

    Future<void> toggleFavorite(RecipeEntity recipe) async {
      if (!sessionService.isAuthenticated) {
        Get.snackbar(
          'Faça login',
          'Entre com sua conta para salvar e organizar suas receitas favoritas.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final alreadyFavorite = favoritesService.isFavoriteSync(recipe);

      try {
        await favoritesService.toggleFavorite(recipe);
        Get.snackbar(
          alreadyFavorite ? 'Favorito removido' : 'Adicionado aos favoritos',
          alreadyFavorite
              ? 'Esta receita foi removida da sua lista de favoritos.'
              : 'Você encontra esta receita na tela de favoritos.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } on FavoritesFailure catch (error) {
        showFavoriteError(error.message);
      } catch (_) {
        showFavoriteError(
          'Não foi possível atualizar seus favoritos agora. Tente novamente.',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        automaticallyImplyLeading: true,
        actions: [
          Obx(() {
            if (!sessionService.isAuthenticated) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Ver favoritos',
              icon: const Icon(Icons.favorite),
              onPressed: () => Get.toNamed(AppRoutes.favorites),
            );
          }),
          TextButton(
            onPressed: () => Get.offAllNamed(AppRoutes.recipeFinder),
            child: const Text('Nova busca'),
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
                maxWidth: 780,
                topPadding: 36,
              );

              return SingleChildScrollView(
                padding: layout.padding,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ResultsHeader(theme: theme, args: args),
                        const SizedBox(height: 28),
                        if (args.message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _InfoBanner(message: args.message!),
                          ),
                        if (args.recipes.isEmpty)
                          EmptyRecipesView(
                            message: args.message ??
                                'Não encontramos receitas com esses ingredientes. Tente ajustar a combinação.',
                          )
                        else
                          ...List.generate(
                            args.recipes.length,
                            (index) {
                              final recipe = args.recipes[index];
                              final heroTag = 'recipe-${recipe.name.hashCode}-$index';
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
                                action: Obx(() {
                                  final isFavorite =
                                      favoritesService.isFavoriteSync(recipe);
                                  return IconButton(
                                    tooltip: isFavorite
                                        ? 'Remover dos favoritos'
                                        : 'Salvar nos favoritos',
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => toggleFavorite(recipe),
                                  );
                                }),
                              );
                            },
                          ),
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

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.theme, required this.args});

  final ThemeData theme;
  final RecipeResultsArgs args;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final chips = args.ingredients
        .map(
          (ingredient) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                    .withOpacity(0.35),
              ),
            ),
            child: Text(
              ingredient,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aqui está o que encontramos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Receitas pensadas a partir dos ingredientes selecionados:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.68),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(children: chips),
          ],
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
            .withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
              .withOpacity(0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.74),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
