import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(theme),
                    const SizedBox(height: 24),
                    _buildIngredientSection(theme),
                    const SizedBox(height: 24),
                    _buildGenerateButton(),
                    const SizedBox(height: 24),
                    _buildResultsSection(theme),
                  ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transforme o que há na sua despensa em refeições deliciosas.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Informe os ingredientes que você tem em casa e descubra até três opções de receitas sem desperdício.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSection(ThemeData theme) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
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
                  icon: const Icon(Icons.add),
                  onPressed: () => controller.addIngredient(controller.ingredientTextController.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (controller.ingredients.isEmpty)
              Text(
                'empty_ingredient_hint'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
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

  Widget _buildGenerateButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: controller.isLoading.value
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Get.theme.colorScheme.onPrimary),
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
