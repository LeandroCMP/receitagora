import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../controllers/recipe_finder_controller.dart';
import '../widgets/empty_recipes_view.dart';
import '../widgets/ingredient_chip.dart';
import '../widgets/recipe_card.dart';

class RecipeFinderPage extends GetView<RecipeFinderController> {
  const RecipeFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr),
        centerTitle: false,
        actions: [
          Obx(() {
            if (controller.isGuest.value) {
              return const SizedBox.shrink();
            }

            final user = controller.sessionService.user;
            if (user == null) {
              return const SizedBox.shrink();
            }

            final initialsSource = user.displayName.isNotEmpty
                ? user.displayName
                : user.email;
            final sanitized = initialsSource.trim();
            final initials = sanitized.isNotEmpty
                ? sanitized.substring(0, 1).toUpperCase()
                : '?';

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.35),
                backgroundImage:
                    user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        initials,
                        style: theme.textTheme.titleMedium,
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.background,
                  theme.colorScheme.surfaceVariant.withOpacity(0.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroHeader(theme),
                      const SizedBox(height: 20),
                      _buildGuestQuota(theme),
                      const SizedBox(height: 20),
                      _buildIngredientSection(theme),
                      const SizedBox(height: 20),
                      _buildGenerateButton(theme),
                      const SizedBox(height: 24),
                      _buildResultsSection(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.75),
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receitas prontas para agora',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conte o que tem em casa e receba sugestões com modo escuro elegante e toques personalizados.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestQuota(ThemeData theme) {
    return Obx(() {
      if (!controller.isGuest.value) {
        return const SizedBox.shrink();
      }

      final remaining = controller.guestSearchesRemaining.value;
      final bool hasQuota = remaining > 0;
      final color = hasQuota ? theme.colorScheme.primary : theme.colorScheme.error;
      final icon = hasQuota ? Icons.timelapse : Icons.lock_outline;
      final message = hasQuota
          ? 'Modo visitante: restam $remaining de ${SessionService.guestDailyLimit} buscas hoje. Cada pesquisa retorna até ${SessionService.guestRecipeLimit} receitas.'
          : 'Modo visitante: limite diário atingido. Faça login com o Google para ter buscas ilimitadas.';

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildIngredientSection(ThemeData theme) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quais ingredientes você tem agora?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.ingredientTextController,
              focusNode: controller.ingredientFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: controller.addIngredient,
              decoration: InputDecoration(
                hintText: 'Digite um ingrediente e pressione enter',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => controller.addIngredient(
                    controller.ingredientTextController.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (controller.ingredients.isEmpty)
              Text(
                'empty_ingredient_hint'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.ingredients
                    .map(
                      (ingredient) => IngredientChip(
                        label: ingredient,
                        onDeleted: () => controller.removeIngredient(ingredient),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: controller.isLoading.value
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('generate_recipes'.tr),
          ),
          onPressed: controller.isLoading.value ? null : controller.fetchRecipes,
        ),
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Obx(
      () {
        if (controller.isLoading.value && controller.recipes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.recipes.isEmpty) {
          final message = controller.errorMessage.value ??
              'Adicione ingredientes para descobrir receitas deliciosas.';
          return EmptyRecipesView(message: message);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sugestões personalizadas',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...controller.recipes.asMap().entries.map(
                  (entry) => RecipeCard(
                    recipe: entry.value,
                    position: entry.key,
                  ),
                ),
          ],
        );
      },
    );
  }
}
