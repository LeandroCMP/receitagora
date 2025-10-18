import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/models/nutrition/diet_plan.dart';
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

    return Obx(() {
      final plan = controller.currentPlan.value;
      final isGenerating = controller.isGenerating.value;
      final isRecording = controller.isRecording.value;
      final shoppingList = plan?.plan.shoppingList ?? const <ShoppingListItem>[];

      if (plan == null) {
        controller.navigateToFormIfNoPlan();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Plano nutricional premium'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Plano nutricional premium'),
          actions: [
            TextButton.icon(
              onPressed: isGenerating ? null : controller.requestProfileEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Atualizar dados'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: shoppingList.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: controller.openShoppingList,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Lista de compras'),
              ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              physics: const BouncingScrollPhysics(),
              child: _PlanArea(
                controller: controller,
                plan: plan,
                isGenerating: isGenerating,
                isRecording: isRecording,
              ),
            ),
          ),
        ),
      );
    });
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
  final NutritionPlan plan;
  final bool isGenerating;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
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
                      ? 'Gerando variação...'
                      : 'Nova variação do cardápio',
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isGenerating ? null : controller.requestFreshPlan,
                icon: const Icon(Icons.manage_search_outlined),
                label: const Text('Gerar com novas informações'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PlanStatusCard(plan: plan),
        const SizedBox(height: 16),
        _MacroSummaryCard(plan: plan.plan),
        const SizedBox(height: 16),
        _PlanDaysView(plan: plan.plan),
        if (plan.plan.shoppingList.isNotEmpty) ...[
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
        if (plan.plan.followUpTips.isNotEmpty) _FollowUpCard(plan: plan.plan),
        const SizedBox(height: 16),
        _CheckInCard(
          controller: controller,
          plan: plan,
          isRecording: isRecording,
        ),
        const SizedBox(height: 16),
        _WeightHistoryCard(plan: plan),
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
    final macros = plan.targets.macroGrams();
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
                subtitle: 'Consumo total por dia',
                color: theme.colorScheme.primary,
              ),
              _MacroChip(
                label: 'Carboidratos',
                value: '${plan.targets.carbsPercentage.toStringAsFixed(0)}%',
                subtitle: '~${macros['carbs']} g / dia',
                color: Colors.orangeAccent,
              ),
              _MacroChip(
                label: 'Proteínas',
                value: '${plan.targets.proteinPercentage.toStringAsFixed(0)}%',
                subtitle: '~${macros['proteins']} g / dia',
                color: Colors.green,
              ),
              _MacroChip(
                label: 'Gorduras',
                value: '${plan.targets.fatPercentage.toStringAsFixed(0)}%',
                subtitle: '~${macros['fats']} g / dia',
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
    this.subtitle,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;

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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
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
              (day) => _PlanDayTile(
                day: day,
                targets: plan.targets,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PlanDayTile extends StatelessWidget {
  const _PlanDayTile({
    required this.day,
    required this.targets,
  });

  final DietPlanDay day;
  final DietPlanTargets targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCalories = day.totalCalories;
    final targetCalories = targets.caloriesPerDay;
    final difference = (totalCalories != null && targetCalories > 0)
        ? totalCalories - targetCalories
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(day.label, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day.focus,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (totalCalories != null && targetCalories > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Planejado: ${totalCalories} kcal · Meta: $targetCalories kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: difference != null && difference.abs() > 80
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
        children: [
          if (totalCalories != null && targetCalories > 0) ...[
            _DailyProgressBar(
              totalCalories: totalCalories,
              targetCalories: targetCalories,
            ),
            const SizedBox(height: 16),
          ],
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

class _DailyProgressBar extends StatelessWidget {
  const _DailyProgressBar({
    required this.totalCalories,
    required this.targetCalories,
  });

  final int totalCalories;
  final int targetCalories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = totalCalories / targetCalories;
    final progress = ratio.clamp(0.0, 1.5);
    final difference = totalCalories - targetCalories;
    final differenceLabel = difference == 0
        ? 'Meta atingida'
        : difference > 0
            ? '+${difference.abs()} kcal acima da meta'
            : '${difference.abs()} kcal abaixo da meta';
    final withinRange = difference.abs() <= 80;
    final indicatorColor = withinRange
        ? theme.colorScheme.primary
        : (difference > 0 ? Colors.orangeAccent : Colors.teal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress > 1 ? 1 : progress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          differenceLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: withinRange
                ? theme.colorScheme.onSurface.withOpacity(0.7)
                : indicatorColor,
            fontWeight: withinRange ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ],
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
    final canRecord = controller.canRecordWeight;
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
          if (!canRecord) ...[
            const SizedBox(height: 8),
            Text(
              'O check-in será liberado quando o ciclo atual terminar. Continue seguindo o cardápio até a data indicada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _ResponsiveFieldRow(
            children: [
              _TextFieldItem(
                controller: controller.checkInController,
                label: 'Peso atual (kg)',
                hint: 'Ex.: 77.2',
                enabled: canRecord && !isRecording,
              ),
              _ButtonItem(
                label: canRecord
                    ? (isRecording ? 'Registrando...' : 'Registrar peso')
                    : 'Aguardar fim do ciclo',
                icon: Icons.published_with_changes,
                isLoading: isRecording,
                onPressed:
                    (!canRecord || isRecording) ? null : controller.recordWeighIn,
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
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

