import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
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
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final favoritesService = Get.find<RecipeFavoritesService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr),
        actions: [
          Obx(() {
            if (controller.isGuest.value) {
              return const SizedBox(width: 8);
            }

            return StreamBuilder<Set<String>>(
              stream: favoritesService.favoriteIdsStream,
              initialData: favoritesService.favoriteIds,
              builder: (context, snapshot) {
                final favoriteIds = snapshot.data ?? favoritesService.favoriteIds;
                final hasFavorites = favoriteIds.isNotEmpty;

                return IconButton(
                  tooltip: 'Ver favoritos',
                  icon: Icon(
                    hasFavorites ? Icons.favorite : Icons.favorite_border,
                    color: hasFavorites ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.favorites),
                );
              },
            );
          }),
          Obx(() {
            if (controller.isGuest.value) {
              return const SizedBox(width: 16);
            }

            final user = controller.currentUser.value;
            if (user == null) {
              return const SizedBox(width: 16);
            }

            final initialsSource = user.name.isNotEmpty ? user.name : user.email;
            final sanitized = initialsSource.trim();
            final initials =
                sanitized.isNotEmpty ? sanitized.substring(0, 1).toUpperCase() : '?';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => Get.toNamed(AppRoutes.userProfile),
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.25),
                  backgroundImage:
                      user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? Text(
                          initials,
                          style: theme.textTheme.titleMedium,
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.06),
                surfaces?.lowest ?? background,
              ),
              background,
              Color.alphaBlend(
                theme.colorScheme.secondary.withOpacity(0.05),
                surfaces?.low ?? background,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 720,
                topPadding: 40,
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
                        _HeroHeader(controller: controller),
                        const SizedBox(height: 32),
                        _GuestNotice(controller: controller),
                        const SizedBox(height: 32),
                        _IngredientComposer(controller: controller),
                        const SizedBox(height: 36),
                        _GenerateButton(controller: controller),
                        const SizedBox(height: 18),
                        Text(
                          'Os resultados aparecem em cartões resumidos '
                          'e você pode abrir cada receita para ver o preparo completo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.62),
                            height: 1.5,
                          ),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.controller});

  final RecipeFinderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final user = controller.currentUser.value;
      final rawName = (user?.name ?? '').trim();
      final firstName = rawName
          .split(' ')
          .firstWhere(
            (segment) => segment.trim().isNotEmpty,
            orElse: () => '',
          )
          .trim();
      final greeting = firstName.isEmpty
          ? 'Convidado'
          : '${firstName[0].toUpperCase()}${firstName.length > 1 ? firstName.substring(1) : ''}';

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 520;
          final padding = EdgeInsets.symmetric(
            horizontal: isCompact ? 24 : 32,
            vertical: isCompact ? 26 : 32,
        );

        final surfaces = theme.extension<ReceitagoraSurfaceColors>();

          return Card(
            elevation: 0,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.35),
                    (surfaces?.surface ?? theme.colorScheme.surface)
                        .withOpacity(0.9),
                  ],
                ),
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroChip(theme: theme),
                          const SizedBox(height: 18),
                          _HeroText(theme: theme, greeting: greeting),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _HeroText(theme: theme, greeting: greeting)),
                          const SizedBox(width: 28),
                          _HeroIllustration(theme: theme),
                        ],
                      ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.onPrimaryContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Sugestões fresquinhas',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.theme, required this.greeting});

  final ThemeData theme;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, $greeting',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Conte o que tem na sua cozinha e receba ideias perfeitas para hoje.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.72),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _HeroMeta(icon: Icons.schedule_rounded, label: '45 min'),
            _HeroMeta(icon: Icons.group_outlined, label: 'Serve até 3'),
            _HeroMeta(icon: Icons.local_fire_department_rounded, label: '470 kcal'),
          ],
        ),
      ],
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
            theme.colorScheme.primaryContainer.withOpacity(0.85),
            theme.colorScheme.primary.withOpacity(0.75),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 32,
            spreadRadius: 6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 140,
        width: 140,
        child: Center(
          child: Icon(
            Icons.restaurant_menu,
            color: surfaces?.highest ?? theme.colorScheme.onPrimaryContainer,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              (surfaces?.high ?? theme.colorScheme.surfaceVariant).withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice({required this.controller});

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
            child: Text(
              'Pronto para descobrir novos sabores? '
              'Adicione ingredientes, escolha suas preferências '
              'e deixe o ChatGPT sugerir combinações personalizadas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.5,
              ),
            ),
          ),
        );
      }

      final remaining = controller.guestSearchesRemaining.value;
      final helper = remaining > 0
          ? 'Modo visitante: restam $remaining de ${SessionService.guestDailyLimit} buscas hoje. '
              'Cada pesquisa entrega até ${SessionService.guestRecipeLimit} receitas resumidas.'
          : 'Você atingiu o limite diário de buscas no modo visitante. Volte amanhã para novas sugestões!';

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      color: theme.colorScheme.primaryContainer.withOpacity(0.32),
                      border: Border.all(
                        color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                            .withOpacity(0.35),
                      ),
                    ),
                    child: Icon(Icons.hourglass_top_rounded,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      helper,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withOpacity(0.72),
                      ),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quais ingredientes você tem hoje?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Digite um ingrediente de cada vez e toque em adicionar para montar sua despensa virtual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.68),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: surfaces?.surface ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                      .withOpacity(0.35),
                ),
              ),
              child: TextField(
                controller: controller.ingredientTextController,
                focusNode: controller.ingredientFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: controller.addIngredient,
                decoration: InputDecoration(
                  hintText: 'Ex.: tomate, frango, manjericão...',
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => controller.addIngredient(
                      controller.ingredientTextController.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.ingredients.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: (surfaces?.high ?? theme.colorScheme.surfaceVariant)
                        .withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!isLoading) ...[
                const Icon(Icons.search_rounded),
                const SizedBox(width: 12),
              ],
              Text('generate_recipes'.tr),
            ],
          ),
        ),
      );
    });
  }
}
