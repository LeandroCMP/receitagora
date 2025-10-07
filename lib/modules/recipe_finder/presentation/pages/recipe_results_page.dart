import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/recipe_entity.dart';
import '../widgets/empty_recipes_view.dart';
import '../widgets/recipe_card.dart';

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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugestões'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surfaceVariant.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerOffset,
                    child: _buildHeader(theme, hasRecipes),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: FadeTransition(
                    opacity: _contentOpacity,
                    child: hasRecipes
                        ? _buildAnimatedList()
                        : EmptyRecipesView(
                            message: _args.message ??
                                'Não encontramos receitas com esses ingredientes.',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool hasRecipes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasRecipes
                ? 'Encontramos ${_args.recipes.length} sugestões para você'
                : 'Vamos tentar novamente?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_args.ingredients.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _args.ingredients
                  .map(
                    (ingredient) => Chip(
                      label: Text(ingredient),
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'Você pode ajustar os ingredientes e tentar novamente quando quiser.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          if (_args.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _args.message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.search),
            label: const Text('Nova pesquisa'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: _args.recipes.length,
      itemBuilder: (context, index) {
        final recipe = _args.recipes[index];
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.16, end: 0),
          duration: Duration(milliseconds: 420 + (index * 90)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 60 * value),
              child: Opacity(
                opacity: 1 - value,
                child: child,
              ),
            );
          },
          child: RecipeCard(
            recipe: recipe,
            position: index,
          ),
        );
      },
    );
  }
}
