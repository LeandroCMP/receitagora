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

class RecipeResultsPage extends StatefulWidget {
  const RecipeResultsPage({super.key});

  @override
  State<RecipeResultsPage> createState() => _RecipeResultsPageState();
}

class _RecipeResultsPageState extends State<RecipeResultsPage>
    with SingleTickerProviderStateMixin {
  late final RecipeResultsArgs _args = _resolveArgs();
  late final AnimationController _controller;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    );
    _headerOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final hasRecipes = _args.recipes.isNotEmpty;
    final background = theme.colorScheme.background;
    final blend = Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.05),
      background,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugestões'),
      ),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [blend, background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -160,
            left: -80,
            child: _ResultsOrb(color: theme.colorScheme.primary.withOpacity(0.24)),
          ),
          Positioned(
            bottom: -180,
            right: -60,
            child: _ResultsOrb(color: theme.colorScheme.secondary.withOpacity(0.2)),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerOpacity,
                    child: SlideTransition(
                      position: _headerOffset,
                      child: _buildHeader(theme, hasRecipes),
                    ),
                  ),
                ),
              ),
              if (hasRecipes)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentOpacity,
                      child: Column(
                        children: List<Widget>.generate(
                          _args.recipes.length,
                          (index) {
                            final recipe = _args.recipes[index];
                            final heroTag = 'recipe-${index + 1}-${recipe.name}';
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.18, end: 0),
                              duration: Duration(milliseconds: 420 + (index * 90)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 48 * value),
                                  child: Opacity(
                                    opacity: 1 - value,
                                    child: child,
                                  ),
                                );
                              },
                              child: RecipeSummaryCard(
                                recipe: recipe,
                                position: index,
                                heroTag: heroTag,
                                onTap: () {
                                  Get.toNamed(
                                    AppRoutes.recipeDetail,
                                    arguments: RecipeDetailArgs(
                                      recipe: recipe,
                                      position: index,
                                      heroTag: heroTag,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentOpacity,
                      child: EmptyRecipesView(
                        message: _args.message ??
                            'Não encontramos receitas com esses ingredientes.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool hasRecipes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.65),
                        theme.colorScheme.primary.withOpacity(0.2),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasRecipes
                            ? 'Sugestões sob medida para agora'
                            : 'Vamos tentar novamente?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_args.message != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _args.message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_args.ingredients.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _args.ingredients
                    .map(
                      (ingredient) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          ingredient,
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.75),
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'Ajuste os ingredientes quando quiser para explorar novas combinações.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.search),
              label: const Text('Nova pesquisa'),
            ),
          ],
        ),
      ),
    );
  }

}

class _ResultsOrb extends StatelessWidget {
  const _ResultsOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.05)],
        ),
      ),
    );
  }
}
