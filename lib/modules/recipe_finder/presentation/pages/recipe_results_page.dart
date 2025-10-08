import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../domain/entities/recipe_entity.dart';
import '../widgets/empty_recipes_view.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_page.dart';

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
    final args = _resolveArgs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        automaticallyImplyLeading: true,
        actions: [
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
              Color.alphaBlend(theme.colorScheme.primary.withOpacity(0.05), background),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontalPadding = width < 420
                  ? 20.0
                  : width < 720
                      ? 28.0
                      : 48.0;
              final maxWidth = width < 820 ? width : 780.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    40,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResultsHeader(theme: theme, args: args),
                        const SizedBox(height: 24),
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
    final chips = args.ingredients
        .map(
          (ingredient) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              ingredient,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
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
