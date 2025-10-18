import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';

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
          child: Obx(
            () {
              final plan = controller.currentPlan.value;
              final isGenerating = controller.isGenerating.value;
              final isRecording = controller.isRecording.value;
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
                      'Responda o questionário premium para que a IA monte um cardápio equilibrado com metas calóricas, macros e lista de compras. '
                      'Depois registre o peso para ajustarmos a estratégia.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _ProfileForm(controller: controller),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
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
                    const SizedBox(height: 32),
                    if (plan == null) ...[
                      _EmptyPlanState(theme: theme),
                    ] else ...[
                      _PlanStatusCard(plan: plan),
                      const SizedBox(height: 20),
                      _MacroSummaryCard(plan: plan.plan),
                      const SizedBox(height: 20),
                      _PlanDaysView(plan: plan.plan),
                      const SizedBox(height: 20),
                      _ShoppingListCard(plan: plan.plan),
                      const SizedBox(height: 20),
                      _FollowUpCard(plan: plan.plan),
                      const SizedBox(height: 20),
                      _CheckInCard(
                        controller: controller,
                        plan: plan,
                        isRecording: isRecording,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({required this.controller});

  final NutritionPlanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seu perfil metabólico',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      hintText: 'Ex.: 172',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controller.weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Peso atual (kg)',
                      hintText: 'Ex.: 78.5',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ChoiceSection<DietActivityLevel>(
              title: 'Rotina de exercícios',
              description: 'Conte para a IA com que frequência você se exercita.',
              options: DietActivityLevel.values,
              selected: controller.activityLevel,
              labelBuilder: (level) => level.label,
              onSelected: controller.setActivityLevel,
            ),
            const SizedBox(height: 16),
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
                    'Avalie seu metabolismo em uma escala de 0 (muito difícil perder peso) a 5 (metabolismo acelerado).',
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
            const SizedBox(height: 16),
            _ChoiceSection<DietGoal>(
              title: 'Objetivo principal',
              description: 'O cardápio será calibrado para este foco.',
              options: DietGoal.values,
              selected: controller.goal,
              labelBuilder: (goal) => goal.label,
              onSelected: controller.setGoal,
            ),
            const SizedBox(height: 16),
            _ChoiceSection<DietPlanInterval>(
              title: 'Frequência do plano',
              description: 'Escolha se deseja um menu semanal ou mensal.',
              options: DietPlanInterval.values,
              selected: controller.interval,
              labelBuilder: (value) => value.label,
              onSelected: controller.setInterval,
            ),
            const SizedBox(height: 16),
            _ChoiceSection<DietCookingStyle>(
              title: 'Modo de preparo',
              description: 'Defina se você cozinha diariamente ou prefere produzir e congelar.',
              options: DietCookingStyle.values,
              selected: controller.cookingStyle,
              labelBuilder: (value) => value.label,
              onSelected: controller.setCookingStyle,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Text(
              'Frequência de lanches',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
            const SizedBox(height: 16),
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
    final statusColor = plan.needsAdjustment
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final statusText = plan.needsAdjustment
        ? 'Vamos ajustar o plano na próxima rodada para acelerar resultados.'
        : 'Continue seguindo o cardápio atual; os resultados estão no caminho certo.';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Situação do plano',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metas diárias',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              plan.strategy,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              plan.hydrationGoal,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
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
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.local_dining, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleMedium),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _PlanDaysView extends StatelessWidget {
  const _PlanDaysView({required this.plan});

  final DietPlan plan;

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
            Text(
              'Agenda de refeições',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...plan.days.map((day) => _PlanDayTile(day: day)).toList(),
          ],
        ),
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
        title: Text(day.label, style: theme.textTheme.titleMedium),
        subtitle: Text(day.focus,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: day.meals
            .map(
              (meal) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restaurant_menu,
                    color: theme.colorScheme.primary.withOpacity(0.8)),
                title: Text(meal.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.description),
                    if (meal.macroFocus != null && meal.macroFocus!.isNotEmpty)
                      Text(
                        meal.macroFocus!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    if (meal.prepNotes != null && meal.prepNotes!.isNotEmpty)
                      Text(
                        'Dica: ${meal.prepNotes!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                trailing: meal.calories != null
                    ? Text('${meal.calories} kcal')
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShoppingListCard extends StatelessWidget {
  const _ShoppingListCard({required this.plan});

  final DietPlan plan;

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
            Text(
              'Lista de compras inteligente',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (plan.shoppingList.isEmpty)
              Text(
                'A IA não gerou itens de compras desta vez. Gere o plano novamente para obter uma lista atualizada.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...plan.shoppingList
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline,
                          color: theme.colorScheme.secondary),
                      title: Text('${item.item} · ${item.quantity}'),
                      subtitle: Text('${item.category}${item.notes != null && item.notes!.isNotEmpty ? ' · ${item.notes}' : ''}'),
                    ),
                  )
                  .toList(),
          ],
        ),
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
    if (plan.followUpTips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orientações para a próxima semana',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...plan.followUpTips
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar peso da semana/mês',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'No último dia do ciclo informe o peso atualizado para que o algoritmo avalie os resultados.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.checkInController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Peso atual (kg)',
                      hintText: 'Ex.: 77.2',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: isRecording ? null : controller.recordWeighIn,
                  icon: isRecording
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.published_with_changes),
                  label: Text(isRecording ? 'Registrando...' : 'Registrar peso'),
                ),
              ],
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.spa_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Ainda não há cardápio gerado. Informe seus dados e toque em "Gerar cardápio" para receber um plano nutricional completo com metas e lista de compras.',
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
