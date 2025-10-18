import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';
import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/modules/recipe_finder/recipe_detail_page.dart';

import 'nutrition_plan_controller.dart';

class NutritionPlanPage extends GetView<NutritionPlanController> {
  const NutritionPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final background = surfaces?.lowest ?? theme.colorScheme.background;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano nutricional premium'),
      ),
      floatingActionButton: Obx(() {
        final shoppingList =
            controller.currentPlan.value?.plan.shoppingList ?? const <ShoppingListItem>[];
        if (shoppingList.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: controller.openShoppingList,
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text('Lista de compras'),
        );
      }),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.05),
                background,
              ),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1024;
              return Obx(
                () {
                  final plan = controller.currentPlan.value;
                  final isGenerating = controller.isGenerating.value;
                  final isRecording = controller.isRecording.value;

                  final form = _ProfileForm(controller: controller);

                  final planView = _PlanArea(
                    controller: controller,
                    plan: plan,
                    isGenerating: isGenerating,
                    isRecording: isRecording,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Chef nutricional da Receita Agora',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preencha o questionário para receber um cardápio equilibrado com metas calóricas, macros e lista de '
                          'compras automática. Registre o peso ao final de cada ciclo para que a estratégia seja ajustada.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: form),
                              const SizedBox(width: 32),
                              Expanded(flex: 4, child: planView),
                            ],
                          )
                        else ...[
                          form,
                          const SizedBox(height: 24),
                          planView,
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlanArea extends StatelessWidget {
  const _PlanArea({
    required this.controller,
    required this.plan,
    required this.isGenerating,
    required this.isRecording,
  });

  final NutritionPlanController controller;
  final NutritionPlan? plan;
  final bool isGenerating;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isGenerating ? null : controller.generatePlan,
            icon: isGenerating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.dining_outlined),
            label: Text(isGenerating ? 'Gerando plano...' : 'Gerar cardápio personalizado'),
          ),
        ),
        if (plan != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isGenerating ? null : controller.generateAlternativePlan,
              icon: isGenerating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(
                isGenerating
                    ? 'Gerando nova versão...'
                    : 'Gerar nova variação do cardápio',
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (plan == null)
          _PlanSectionCard(
            title: 'Resultado do cardápio',
            child: _EmptyPlanState(theme: theme),
          )
        else ...[
          _PlanStatusCard(plan: plan!),
          const SizedBox(height: 16),
          _MacroSummaryCard(plan: plan!.plan),
          const SizedBox(height: 16),
          _PlanDaysView(plan: plan!.plan),
          if (plan!.plan.shoppingList.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: controller.openShoppingList,
                icon: const Icon(Icons.shopping_cart_checkout_outlined),
                label: const Text('Abrir lista de compras completa'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (plan!.plan.followUpTips.isNotEmpty) _FollowUpCard(plan: plan!.plan),
          const SizedBox(height: 16),
          _CheckInCard(
            controller: controller,
            plan: plan!,
            isRecording: isRecording,
          ),
        ],
      ],
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({required this.controller});

  final NutritionPlanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PlanSectionCard(
      title: 'Seu perfil metabólico',
      description:
          'Responda de forma sincera para que a IA calcule metas realistas e mantenha o cardápio adaptado ao seu ritmo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveFieldRow(
            children: [
              _TextFieldItem(
                controller: controller.heightController,
                label: 'Altura (cm)',
                hint: 'Ex.: 172',
              ),
              _TextFieldItem(
                controller: controller.weightController,
                label: 'Peso atual (kg)',
                hint: 'Ex.: 78.5',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChoiceSection<DietActivityLevel>(
            title: 'Rotina de exercícios',
            description: 'Conte para a IA com que frequência você se exercita.',
            options: DietActivityLevel.values,
            selected: controller.activityLevel,
            labelBuilder: (level) => level.label,
            onSelected: controller.setActivityLevel,
          ),
          const SizedBox(height: 20),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facilidade para emagrecer',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avalie seu metabolismo: 0 (muito difícil perder peso) a 5 (metabolismo acelerado).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Slider(
                  value: controller.metabolicEase.value,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: controller.metabolicEase.value.round().toString(),
                  onChanged: (value) => controller.metabolicEase.value = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ChoiceSection<DietGoal>(
            title: 'Objetivo principal',
            description: 'O cardápio será calibrado para este foco.',
            options: DietGoal.values,
            selected: controller.goal,
            labelBuilder: (goal) => goal.label,
            onSelected: controller.setGoal,
          ),
          const SizedBox(height: 20),
          _ChoiceSection<DietPlanInterval>(
            title: 'Frequência do plano',
            description: 'Prefere cardápio semanal ou mensal?',
            options: DietPlanInterval.values,
            selected: controller.interval,
            labelBuilder: (value) => value.label,
            onSelected: controller.setInterval,
          ),
          const SizedBox(height: 20),
          _ChoiceSection<DietCookingStyle>(
            title: 'Modo de preparo',
            description: 'Defina se cozinha diariamente ou prefere preparar e congelar.',
            options: DietCookingStyle.values,
            selected: controller.cookingStyle,
            labelBuilder: (value) => value.label,
            onSelected: controller.setCookingStyle,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: controller.prefersBrazilianCuisine.value,
            onChanged: controller.toggleBrazilianCuisine,
            title: const Text('Priorizar sabores brasileiros'),
            subtitle: const Text('Ative para privilegiar temperos e preparos nacionais.'),
          ),
          SwitchListTile.adaptive(
            value: controller.prefersSeasonalProduce.value,
            onChanged: controller.toggleSeasonalProduce,
            title: const Text('Usar ingredientes sazonais'),
            subtitle: const Text('Sugestões alinhadas à safra para economizar e ganhar sabor.'),
          ),
          const SizedBox(height: 12),
          Text(
            'Frequência de lanches',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NutritionPlanController.snackOptions
                .map(
                  (option) => Obx(
                    () => ChoiceChip(
                      label: Text(option),
                      selected: controller.snackFrequency.value == option,
                      onSelected: (_) => controller.setSnackFrequency(option),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller.notesController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Observações adicionais',
              hintText: 'Restrições médicas, utensílios disponíveis, preferências familiares...',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.description,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String title;
  final String description;
  final List<T> options;
  final Rx<T> selected;
  final String Function(T value) labelBuilder;
  final void Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => ChoiceChip(
                    label: Text(labelBuilder(option)),
                    selected: selected.value == option,
                    onSelected: (_) => onSelected(option),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextCheckIn = plan.nextCheckInAt;
    final dateLabel = '${nextCheckIn.day.toString().padLeft(2, '0')}/${nextCheckIn.month.toString().padLeft(2, '0')}/${nextCheckIn.year}';
    final statusColor = plan.needsAdjustment ? theme.colorScheme.error : theme.colorScheme.primary;
    final statusText = plan.needsAdjustment
        ? 'Vamos ajustar o plano na próxima rodada para acelerar resultados.'
        : 'Continue seguindo o cardápio atual; os resultados estão no caminho certo.';

    return _PlanSectionCard(
      title: 'Situação do plano',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.timeline_outlined, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Próximo check-in: $dateLabel',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Peso inicial: ${plan.startingWeightKg.toStringAsFixed(1)} kg · Último registro: ${plan.lastWeighInKg.toStringAsFixed(1)} kg',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  const _MacroSummaryCard({required this.plan});

  final DietPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PlanSectionCard(
      title: 'Metas diárias',
      description: plan.strategy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MacroChip(
                label: 'Calorias',
                value: '${plan.targets.caloriesPerDay} kcal',
                color: theme.colorScheme.primary,
              ),
              _MacroChip(
                label: 'Carboidratos',
                value: '${plan.targets.carbsPercentage.toStringAsFixed(0)}%',
                color: Colors.orangeAccent,
              ),
              _MacroChip(
                label: 'Proteínas',
                value: '${plan.targets.proteinPercentage.toStringAsFixed(0)}%',
                color: Colors.green,
              ),
              _MacroChip(
                label: 'Gorduras',
                value: '${plan.targets.fatPercentage.toStringAsFixed(0)}%',
                color: Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.hydrationGoal,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_dining, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDaysView extends StatelessWidget {
  const _PlanDaysView({required this.plan});

  final DietPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PlanSectionCard(
      title: 'Agenda de refeições',
      child: Column(
        children: plan.days
            .map(
              (day) => _PlanDayTile(day: day),
            )
            .toList(),
      ),
    );
  }
}

class _PlanDayTile extends StatelessWidget {
  const _PlanDayTile({required this.day});

  final DietPlanDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(day.label, style: theme.textTheme.titleMedium),
        subtitle: Text(
          day.focus,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        children: [
          for (var i = 0; i < day.meals.length; i++) ...[
            _PlanMealTile(day: day, meal: day.meals[i]),
            if (i < day.meals.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class _PlanMealTile extends StatelessWidget {
  const _PlanMealTile({
    required this.day,
    required this.meal,
  });

  final DietPlanDay day;
  final DietPlanMeal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metadata = <Widget>[];
    if (meal.calories != null) {
      metadata.add(_MealMetaChip(
        icon: Icons.local_fire_department_outlined,
        label: '${meal.calories} kcal',
      ));
    }
    if (meal.duration != null && meal.duration!.isNotEmpty) {
      metadata.add(_MealMetaChip(
        icon: Icons.schedule_outlined,
        label: meal.duration!,
      ));
    }
    if (meal.difficulty != null && meal.difficulty!.isNotEmpty) {
      metadata.add(_MealMetaChip(
        icon: Icons.leaderboard_outlined,
        label: meal.difficulty!,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(meal.description),
                  if (meal.macroFocus != null && meal.macroFocus!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      meal.macroFocus!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                  if (meal.prepNotes != null && meal.prepNotes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Dica: ${meal.prepNotes!}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metadata,
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _openRecipe(day, meal),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Ver ingredientes e preparo completos'),
          ),
        ),
      ],
    );
  }

  void _openRecipe(DietPlanDay day, DietPlanMeal meal) {
    final recipe = _mealToRecipe(meal);
    final heroTag =
        'nutrition-${day.label}-${meal.name}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    Get.to(() => RecipeDetailPage(recipe: recipe, heroTag: heroTag));
  }

  RecipeEntity _mealToRecipe(DietPlanMeal meal) {
    String sanitize(String? value, String fallback) {
      if (value == null) {
        return fallback;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }

    final ingredients = meal.ingredients.isNotEmpty
        ? meal.ingredients
        : <String>[sanitize(meal.macroFocus, 'Ingredientes não especificados.')];
    final steps = meal.steps.isNotEmpty
        ? meal.steps
        : <String>[sanitize(meal.prepNotes, 'Prepare conforme indicado na descrição.')];

    return RecipeEntity(
      name: meal.name,
      description: sanitize(meal.description, 'Receita gerada pelo plano nutricional.'),
      ingredients: ingredients,
      steps: steps,
      difficulty: sanitize(meal.difficulty, 'Dificuldade não informada'),
      duration: sanitize(meal.duration, 'Tempo não informado'),
    );
  }
}

class _MealMetaChip extends StatelessWidget {
  const _MealMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.plan});

  final DietPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PlanSectionCard(
      title: 'Orientações para a próxima semana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: plan.followUpTips
            .map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.controller,
    required this.plan,
    required this.isRecording,
  });

  final NutritionPlanController controller;
  final NutritionPlan plan;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PlanSectionCard(
      title: 'Registrar peso do ciclo',
      description:
          'No último dia da semana ou do mês informe o peso atualizado para que o algoritmo avalie os resultados e ajuste o cardápio.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximo registro sugerido: ${plan.nextCheckInAt.day.toString().padLeft(2, '0')}/${plan.nextCheckInAt.month.toString().padLeft(2, '0')}/${plan.nextCheckInAt.year}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          _ResponsiveFieldRow(
            children: [
              _TextFieldItem(
                controller: controller.checkInController,
                label: 'Peso atual (kg)',
                hint: 'Ex.: 77.2',
              ),
              _ButtonItem(
                label: isRecording ? 'Registrando...' : 'Registrar peso',
                icon: Icons.published_with_changes,
                isLoading: isRecording,
                onPressed: isRecording ? null : controller.recordWeighIn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanSectionCard extends StatelessWidget {
  const _PlanSectionCard({
    this.title,
    this.description,
    required this.child,
  });

  final String? title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
            ],
            if (description != null) ...[
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({required this.children});

  final List<_FormRowChild> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canSplit = constraints.maxWidth >= 520 && children.length > 1;
        if (!canSplit) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i].build(context),
                if (i != children.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        final left = <_FormRowChild>[];
        final right = <_FormRowChild>[];
        for (var i = 0; i < children.length; i++) {
          (i.isEven ? left : right).add(children[i]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ResponsiveFieldRow(children: left)),
            const SizedBox(width: 16),
            Expanded(child: _ResponsiveFieldRow(children: right)),
          ],
        );
      },
    );
  }
}

abstract class _FormRowChild {
  Widget build(BuildContext context);
}

class _TextFieldItem extends _FormRowChild {
  _TextFieldItem({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

class _ButtonItem extends _FormRowChild {
  _ButtonItem({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.spa_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Ainda não há cardápio gerado. Informe seus dados e toque em "Gerar cardápio" para receber metas nutricionais e a lista de compras automática.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
