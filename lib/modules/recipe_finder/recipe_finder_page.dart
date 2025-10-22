import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';
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
                          _PremiumShortcuts(controller: controller),
                          _IngredientComposer(controller: controller),
                          const SizedBox(height: 32),
                          _GenerateButton(controller: controller),
                          _HistoryShortcut(controller: controller),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.72),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Text(
                            'Seleção sob medida',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSecondaryContainer,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      'Adicione seus ingredientes e deixe o Receita Agora sugerir combinações pensadas para o seu dia.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: isCompact ? 14 : 15,
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.78),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surface.withOpacity(0.28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Receitas rápidas, equilibradas e sempre prontas para salvar.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.78),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                return textColumn;
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
          ? 'Modo visitante: restam $remaining de ${controller.guestDailyLimit.value} buscas hoje. Cada pesquisa retorna até ${controller.guestRecipeLimit.value} receitas.'
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

class _PremiumShortcuts extends StatelessWidget {
  const _PremiumShortcuts({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Obx(() {
      if (controller.isGuest.value) {
        return const SizedBox.shrink();
      }

      final hasPremium = controller.hasPremiumAccess.value;
      final colorScheme = theme.colorScheme;

      if (!hasPremium) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withOpacity(0.12),
                          ),
                          child: Icon(
                            Icons.workspace_premium_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Desbloqueie experiências completas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'O plano Premium libera o Laboratório de Ingredientes com o chef IA e um cardápio nutricional guiado com lista de compras automática.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.72),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: controller.openPremiumPlans,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Conhecer o Premium'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer.withOpacity(0.25),
                        ),
                        child: Icon(
                          Icons.star_rate_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Recursos Premium ao seu alcance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Acesse rapidamente o Laboratório de Ingredientes e o plano nutricional para organizar sua semana.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.72),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final itemWidth = maxWidth >= 520 ? 260.0 : maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _PremiumShortcutButton(
                            icon: Icons.local_dining_rounded,
                            title: 'Plano nutricional',
                            description:
                                'Revise metas diárias, check-ins de peso e cardápio completo.',
                            width: itemWidth,
                            backgroundColor: surfaces?.surface,
                            onTap: controller.openNutritionPlan,
                          ),
                          _PremiumShortcutButton(
                            icon: Icons.science_rounded,
                            title: 'Laboratório de ingredientes',
                            description:
                                'Teste substituições e receba relatórios do chef IA.',
                            width: itemWidth,
                            backgroundColor:
                                colorScheme.secondaryContainer.withOpacity(0.35),
                            onTap: controller.openIngredientLab,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      );
    });
  }
}

class _PremiumShortcutButton extends StatelessWidget {
  const _PremiumShortcutButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.width,
    this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final double width;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: backgroundColor ?? colorScheme.surfaceVariant.withOpacity(0.55),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Abrir',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      'Pronto para explorar? Gere receitas, organize favoritos e compartilhe artes exclusivas quando estiver autenticado.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.66),
        height: 1.5,
      ),
    );
  }
}

class _HistoryShortcut extends StatelessWidget {
  const _HistoryShortcut({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final historyService = controller.recipeHistoryService;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<RecipeHistoryEntry>>(
      stream: historyService.historyStream,
      initialData: historyService.history,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? historyService.history;
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        final latest = entries.first;
        final ingredients = _formatIngredients(latest.ingredients);
        final relativeTime = _formatRelativeTime(latest.timestamp);

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.12),
                        ),
                        child: Icon(
                          Icons.history_toggle_off_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Retome combinações recentes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Última busca: $ingredients',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$relativeTime • ${latest.totalRecipes} receita${latest.totalRecipes == 1 ? '' : 's'} salvas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: controller.openHistory,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Ver histórico de buscas'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatIngredients(List<String> ingredients) {
    if (ingredients.isEmpty) {
      return 'Ingredientes não informados';
    }
    if (ingredients.length <= 3) {
      return ingredients.join(', ');
    }
    final display = ingredients.take(3).join(', ');
    final remaining = ingredients.length - 3;
    return '$display +$remaining';
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final local = timestamp.toLocal();
    final difference = now.difference(local);

    if (difference.inDays >= 2) {
      return 'Atualizado há ${difference.inDays} dias';
    }
    if (difference.inDays == 1) {
      return 'Atualizado há 1 dia';
    }
    if (difference.inHours >= 2) {
      return 'Atualizado há ${difference.inHours} horas';
    }
    if (difference.inHours == 1) {
      return 'Atualizado há 1 hora';
    }
    if (difference.inMinutes >= 2) {
      return 'Atualizado há ${difference.inMinutes} minutos';
    }
    if (difference.inMinutes == 1) {
      return 'Atualizado há 1 minuto';
    }

    return 'Atualizado agora mesmo';
  }
}
