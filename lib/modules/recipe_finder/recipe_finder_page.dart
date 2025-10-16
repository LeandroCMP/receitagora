import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'recipe_finder_controller.dart';
import 'widgets/ingredient_chip.dart';

class RecipeFinderPage extends GetView<RecipeFinderController> {
  const RecipeFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesService = Get.find<RecipeFavoritesService>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Icons.dinner_dining_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Receita Agora',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.isGuest.value) {
              return const SizedBox(width: 16);
            }

            return StreamBuilder<Set<String>>(
              stream: favoritesService.favoriteIdsStream,
              initialData: favoritesService.favoriteIds,
              builder: (context, snapshot) {
                final favoriteIds = snapshot.data ?? favoritesService.favoriteIds;
                final hasFavorites = favoriteIds.isNotEmpty;

                return IconButton(
                  tooltip: 'Ver receitas favoritas',
                  icon: Icon(
                    hasFavorites ? Icons.favorite_rounded : Icons.favorite_outline,
                    color: hasFavorites ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.favorites),
                );
              },
            );
          }),
          Obx(() {
            if (controller.isGuest.value) {
              return const SizedBox(width: 20);
            }

            final user = controller.currentUser.value;
            if (user == null) {
              return const SizedBox(width: 20);
            }

            final initialsSource = user.name.isNotEmpty ? user.name : user.email;
            final sanitized = initialsSource.trim();
            final initials =
                sanitized.isNotEmpty ? sanitized.substring(0, 1).toUpperCase() : '?';

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => Get.toNamed(AppRoutes.userProfile),
                borderRadius: BorderRadius.circular(100),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  backgroundImage:
                      user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? Text(
                          initials,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 720,
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
                          _WelcomeSection(controller: controller),
                          const SizedBox(height: 28),
                          _DailyLimitNotice(controller: controller),
                          const SizedBox(height: 28),
                          _IngredientComposer(controller: controller),
                          const SizedBox(height: 32),
                          _GenerateButton(controller: controller),
                          const SizedBox(height: 20),
                          _HelperFooter(theme: theme),
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

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Obx(() {
      final user = controller.currentUser.value;
      final segments = (user?.name ?? '')
          .trim()
          .split(' ')
        ..removeWhere((segment) => segment.trim().isEmpty);
      final firstName = segments.isNotEmpty ? segments.first : null;
      final greeting = firstName != null
          ? '${firstName[0].toUpperCase()}${firstName.substring(1).toLowerCase()}'
          : 'convidado';

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 18),
              child: child,
            ),
          );
        },
        child: Card(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  (surfaces?.highest ?? theme.colorScheme.background),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;

                final textColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.brunch_dining_rounded,
                            color: theme.colorScheme.onSecondaryContainer,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Seleção sob medida',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Olá, $greeting!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: isCompact ? 26 : 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Conte o que está à sua disposição e receba receitas equilibradas em sabor, tempo e rendimento.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: isCompact ? 14 : 15,
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                );

                final illustration = _HeroIllustration(theme: theme);

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      textColumn,
                      const SizedBox(height: 28),
                      illustration,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: textColumn),
                    const SizedBox(width: 32),
                    illustration,
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

class _DailyLimitNotice extends StatelessWidget {
  const _DailyLimitNotice({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Obx(() {
      if (!controller.isGuest.value) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: theme.colorScheme.tertiary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Adicione ingredientes, revise suas preferências no perfil e explore as combinações pensadas para hoje.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final remaining = controller.guestSearchesRemaining.value;
      final helper = remaining > 0
          ? 'Modo visitante: restam $remaining de ${SessionService.guestDailyLimit} buscas hoje. Cada pesquisa retorna até ${SessionService.guestRecipeLimit} receitas.'
          : 'Você alcançou o limite diário no modo visitante. Volte amanhã ou faça login para liberar buscas ilimitadas.';

      return Card(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: (surfaces?.surface ?? theme.colorScheme.surface),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  helper,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _IngredientComposer extends StatelessWidget {
  const _IngredientComposer({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monte sua despensa virtual',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Digite um ingrediente por vez, confirme com Enter ou no botão ao lado e acompanhe abaixo a lista montada.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.68),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 62,
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Positioned.fill(
                    child: TextField(
                      controller: controller.ingredientTextController,
                      focusNode: controller.ingredientFocusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: controller.addIngredient,
                      decoration: InputDecoration(
                        hintText: 'Ex.: tomate, frango, manjericão...',
                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          18,
                          76,
                          18,
                        ),
                        filled: false,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      elevation: 4,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      onPressed: () => controller.addIngredient(
                        controller.ingredientTextController.text,
                      ),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (controller.ingredients.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color:
                        (surfaces?.high ?? theme.colorScheme.surfaceVariant).withOpacity(0.35),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'empty_ingredient_hint'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.64),
                      height: 1.45,
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: controller.ingredients
                    .map(
                      (ingredient) => IngredientChip(
                        label: ingredient,
                        onDeleted: () => controller.removeIngredient(ingredient),
                      ),
                    )
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isLoading = controller.isLoading.value;
      return FilledButton(
        onPressed: isLoading ? null : controller.fetchRecipes,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                const Icon(Icons.search_rounded),
                const SizedBox(width: 12),
              ],
              Text(
                isLoading ? 'Buscando receitas...' : 'Encontrar receitas',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _HelperFooter extends StatelessWidget {
  const _HelperFooter({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Os resultados são apresentados em cartões ricos com preparo completo, sugestões de porção e possibilidade de salvar ou compartilhar quando estiver autenticado.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.62),
        height: 1.5,
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.primary.withOpacity(0.55),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 38,
            spreadRadius: 6,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SizedBox(
        height: 150,
        width: 150,
        child: Center(
          child: Icon(
            Icons.restaurant_menu_rounded,
            color: surfaces?.highest ?? theme.colorScheme.onPrimary,
            size: 56,
          ),
        ),
      ),
    );
  }
}
