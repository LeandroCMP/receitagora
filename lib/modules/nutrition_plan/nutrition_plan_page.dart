import 'dart:math' as math;

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
        final hasSnapshot = controller.hasLoadedInitialSnapshot;
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
              child: Center(
                child: hasSnapshot
                    ? _EmptyPlanView(controller: controller)
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
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

class _EmptyPlanView extends StatelessWidget {
  const _EmptyPlanView({required this.controller});

  final NutritionPlanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final cardColor = surfaces?.low ?? theme.colorScheme.surfaceVariant;
    final onCard = theme.colorScheme.onSurface;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Monte seu primeiro cardápio',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onCard,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Responda um questionário rápido para que nossa IA calcule metas personalizadas e gere uma dieta completa com lista de compras.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onCard.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: controller.requestFreshPlan,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('Preencher questionário'),
                ),
              ),
            ],
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
  final NutritionPlan plan;
  final bool isGenerating;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isGenerating
                ? null
                : () => _showUpdateOptions(context, controller),
            icon: isGenerating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.refresh_outlined),
            label: Text(
              isGenerating
                  ? 'Processando...'
                  : 'Atualizar cardápio premium',
            ),
          ),
        ),
        const SizedBox(height: 24),
        _PlanStatusCard(controller: controller, plan: plan),
        const SizedBox(height: 16),
        _DailyFocusCard(controller: controller, plan: plan),
        const SizedBox(height: 16),
        _MacroSummaryCard(plan: plan.plan),
        const SizedBox(height: 16),
        _HydrationCoachCard(plan: plan),
        const SizedBox(height: 16),
        _MovementCoachCard(plan: plan),
        const SizedBox(height: 16),
        _SunlightCoachCard(plan: plan),
        const SizedBox(height: 16),
        _MindfulBreakCard(plan: plan),
        const SizedBox(height: 16),
        _SleepRoutineCard(plan: plan),
        const SizedBox(height: 16),
        _WellnessDigestCard(plan: plan),
        const SizedBox(height: 16),
        _ProgressOverviewCard(controller: controller, plan: plan),
        const SizedBox(height: 16),
        _PlanDaysView(controller: controller, plan: plan),
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

Future<void> _showUpdateOptions(
  BuildContext context,
  NutritionPlanController controller,
) async {
  final action = await showModalBottomSheet<_PlanUpdateAction>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _PlanUpdateSheet(),
  );

  switch (action) {
    case _PlanUpdateAction.variation:
      await controller.generateAlternativePlan();
      break;
    case _PlanUpdateAction.newProfile:
      await controller.requestFreshPlan();
      break;
    case null:
      break;
  }
}

enum _PlanUpdateAction { variation, newProfile }

class _PlanUpdateSheet extends StatelessWidget {
  const _PlanUpdateSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Como deseja atualizar?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Escolha se prefere apenas variar as receitas mantendo as metas atuais ou se quer responder o questionário novamente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: () => Navigator.of(context).pop(_PlanUpdateAction.variation),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.auto_awesome_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Gerar nova variação'),
              subtitle: const Text('Mantém suas metas e preferências atuais, trocando as combinações do cardápio.'),
            ),
            ListTile(
              onTap: () => Navigator.of(context).pop(_PlanUpdateAction.newProfile),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.manage_search_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Refazer questionário'),
              subtitle: const Text('Atualize dados de altura, peso ou preferências antes de gerar um novo plano.'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = plan.weightHistory.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final startingWeight = plan.startingWeightKg;
    final latestWeight = plan.lastWeighInKg;
    final delta = latestWeight - startingWeight;

    String _formatWeight(double value) {
      final normalized = value.abs() < 0.05 ? 0.0 : value;
      final formatted = normalized.toStringAsFixed(1).replaceAll('.', ',');
      return '$formatted kg';
    }

    String _formatDate(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    Widget _buildMetric(String label, String value, {Color? color}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    String deltaLabel;
    Color deltaColor;
    if (delta.abs() < 0.05) {
      deltaLabel = 'Sem variação relevante';
      deltaColor = theme.colorScheme.onSurface.withOpacity(0.6);
    } else {
      final prefix = delta > 0 ? '+' : '-';
      deltaLabel = '$prefix${delta.abs().toStringAsFixed(1).replaceAll('.', ',')} kg';
      deltaColor = delta > 0
          ? theme.colorScheme.error
          : theme.colorScheme.primary;
    }

    return _PlanSectionCard(
      title: 'Histórico de peso',
      description: history.isEmpty
          ? 'Registre o peso ao final de cada ciclo para acompanhar a evolução.'
          : 'Acompanhe os registros anteriores para entender a evolução do plano.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = <Widget>[
                _buildMetric('Peso inicial', _formatWeight(startingWeight)),
                _buildMetric('Último peso', _formatWeight(latestWeight)),
                _buildMetric('Variação total', deltaLabel, color: deltaColor),
              ];

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      metrics[i],
                      if (i < metrics.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: metrics[0]),
                  const SizedBox(width: 12),
                  Expanded(child: metrics[1]),
                  const SizedBox(width: 12),
                  Expanded(child: metrics[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (history.isEmpty)
            Text(
              'Ainda não há registros de peso para este plano.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(
              children: [
                for (var i = 0; i < history.length; i++)
                  _WeightHistoryTile(
                    entry: history[i],
                    previous: i + 1 < history.length ? history[i + 1] : null,
                    formatDate: _formatDate,
                    formatWeight: _formatWeight,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeightHistoryTile extends StatelessWidget {
  const _WeightHistoryTile({
    required this.entry,
    this.previous,
    required this.formatDate,
    required this.formatWeight,
  });

  final WeightEntry entry;
  final WeightEntry? previous;
  final String Function(DateTime date) formatDate;
  final String Function(double weight) formatWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difference = previous != null ? entry.weightKg - previous!.weightKg : 0;
    final hasDifference = previous != null && difference.abs() >= 0.05;

    Color? diffColor;
    String? diffLabel;
    if (hasDifference) {
      final prefix = difference > 0 ? '+' : '-';
      diffLabel = '$prefix${difference.abs().toStringAsFixed(1).replaceAll('.', ',')} kg';
      diffColor = difference > 0
          ? theme.colorScheme.error
          : theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fitness_center, color: theme.colorScheme.primary.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(entry.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Peso registrado: ${formatWeight(entry.weightKg)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (diffLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Variação desde o registro anterior: $diffLabel',
                      style: theme.textTheme.bodySmall?.copyWith(color: diffColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.controller, required this.plan});

  final NutritionPlanController controller;
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

    final info = controller.todayProgressInfo;
    final daysUntil = controller.daysUntilNextCheckIn;
    final streak = controller.adherenceStreakDays;
    final chips = <Widget>[
      _StatusChip(
        icon: Icons.calendar_today_outlined,
        label: daysUntil <= 0
            ? 'Check-in disponível'
            : '$daysUntil dia(s) até o check-in',
        color: theme.colorScheme.primary,
      ),
      _StatusChip(
        icon: Icons.local_fire_department_outlined,
        label: streak <= 0
            ? 'Construa sua sequência'
            : '$streak dia(s) seguidos no plano',
        color: theme.colorScheme.secondary,
      ),
    ];
    if (info != null) {
      final pending = info.pendingMeals;
      chips.add(
        _StatusChip(
          icon: Icons.fastfood_outlined,
          label: pending == 0
              ? 'Refeições de hoje concluídas'
              : '$pending refeição(ões) pendentes hoje',
          color: pending == 0 ? theme.colorScheme.primary : Colors.orangeAccent,
        ),
      );
    }

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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
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

class _HydrationCoachCard extends StatelessWidget {
  const _HydrationCoachCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hydrationPlan = plan.plan.hydrationPlan;
    final enabled = plan.profile.hydrationCoachEnabled;

    if (!enabled) {
      return _PlanSectionCard(
        title: 'Coach de hidratação automático',
        child: Text(
          'Ative os lembretes no questionário para receber metas calculadas e avisos de hidratação sem esforço.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final reminders = hydrationPlan.reminders;
    final litersLabel = hydrationPlan.liters
        .toStringAsFixed(hydrationPlan.liters >= 3 ? 1 : 2)
        .replaceAll('.', ',');

    return _PlanSectionCard(
      title: 'Coach de hidratação automático',
      description:
          'Lembretes distribuídos ao longo do dia para manter energia, foco e bem-estar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.water_drop_outlined,
                label: 'Meta diária',
                value: '$litersLabel L (${hydrationPlan.totalMl} ml)',
              ),
              if (reminders.isNotEmpty)
                _InfoChip(
                  icon: Icons.alarm_outlined,
                  label: 'Lembretes',
                  value: '${reminders.length}x ao dia',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hydrationPlan.tip,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          if (reminders.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...reminders
                .map((slot) => _HydrationReminderTile(slot: slot))
                .toList(),
          ],
        ],
      ),
    );
  }
}

class _MovementCoachCard extends StatelessWidget {
  const _MovementCoachCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = plan.plan.movementRoutine;
    final enabled = plan.profile.movementCoachEnabled && info.enabled;

    if (!enabled) {
      return _PlanSectionCard(
        title: 'Pausas ativas guiadas',
        child: Text(
          'Ative as pausas ativas no questionário para receber lembretes automáticos de alongamentos e mobilidade.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final slots = info.slots;

    return _PlanSectionCard(
      title: 'Pausas ativas guiadas',
      description:
          'Alertas discretos ao longo do dia ajudam a quebrar o sedentarismo sem demandar planejamento manual.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          if (slots.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: slots
                  .map(
                    (slot) => _InfoChip(
                      icon: Icons.fitness_center_outlined,
                      label: slot.formattedTime,
                      value: '${slot.durationMinutes} min',
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            ...slots
                .map(
                  (slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slot.activity,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
          if (info.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Dicas do coach',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...info.tips
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }
}

class _SunlightCoachCard extends StatelessWidget {
  const _SunlightCoachCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = plan.plan.sunlightRoutine;
    final enabled = plan.profile.sunlightCoachEnabled && info.enabled;

    if (!enabled) {
      return _PlanSectionCard(
        title: 'Rotina de luz natural',
        child: Text(
          'Ative o coach de luz natural no questionário para receber lembretes seguros de exposição ao sol.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final timeLabel =
        '${info.reminderHour.toString().padLeft(2, '0')}:${info.reminderMinute.toString().padLeft(2, '0')}';

    return _PlanSectionCard(
      title: 'Rotina de luz natural',
      description: 'Um lembrete diário ajuda a sincronizar ritmos circadianos e reforçar vitamina D.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.wb_sunny_outlined,
                label: 'Horário ideal',
                value: timeLabel,
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: 'Duração sugerida',
                value: '${info.durationMinutes} min',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            info.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          if (info.benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Benefícios esperados',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...info.benefits
                .map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_florist_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
          if (info.cautions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Cuidados rápidos',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...info.cautions
                .map(
                  (caution) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          size: 16,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            caution,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }
}

class _MindfulBreakCard extends StatelessWidget {
  const _MindfulBreakCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = plan.profile.mindfulBreaksEnabled;
    final timeLabel =
        '${plan.plan.mindfulBreakHour.toString().padLeft(2, '0')}:${plan.plan.mindfulBreakMinute.toString().padLeft(2, '0')}';

    if (!enabled) {
      return _PlanSectionCard(
        title: 'Pausa de bem-estar',
        child: Text(
          'Quer receber um lembrete diário para alongar e respirar? Ative a pausa de bem-estar no questionário do plano.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    return _PlanSectionCard(
      title: 'Pausa de bem-estar',
      description:
          'Uma notificação discreta ajuda você a desacelerar sem precisar lembrar sozinho.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoChip(
            icon: Icons.self_improvement_outlined,
            label: 'Horário sugerido',
            value: timeLabel,
          ),
          const SizedBox(height: 12),
          Text(
            plan.plan.mindfulBreakMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepRoutineCard extends StatelessWidget {
  const _SleepRoutineCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routine = plan.plan.sleepRoutine;
    final enabled = plan.profile.sleepCoachEnabled && routine.hasReminder;
    final bedtimeLabel = plan.profile.sleepWindow.label;
    final reminderLabel =
        '${routine.reminderHour.toString().padLeft(2, '0')}:${routine.reminderMinute.toString().padLeft(2, '0')}';

    if (!enabled) {
      return _PlanSectionCard(
        title: 'Rotina do sono inteligente',
        child: Text(
          'Ative a rotina do sono no questionário para receber um aviso automático antes de dormir e sugestões de relaxamento.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final tips = routine.windDownTips;
    final summary = routine.windDownSummary.isEmpty
        ? plan.profile.sleepWindow.summary
        : routine.windDownSummary;

    return _PlanSectionCard(
      title: 'Rotina do sono inteligente',
      description: 'Desacelere com dicas rápidas 30 minutos antes do horário ideal de descanso.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.nights_stay_outlined,
                label: 'Lembrete diário',
                value: reminderLabel,
              ),
              _InfoChip(
                icon: Icons.bedtime_outlined,
                label: 'Janela preferida',
                value: bedtimeLabel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WellnessDigestCard extends StatelessWidget {
  const _WellnessDigestCard({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digest = plan.plan.wellnessDigest;
    final enabled = plan.profile.wellnessDigestEnabled && digest.enabled;

    if (!enabled) {
      return _PlanSectionCard(
        title: 'Resumo automático de bem-estar',
        child: Text(
          'Ative o resumo automático para receber um lembrete com os principais destaques do plano antes do próximo check-in.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final highlights = digest.highlights;
    final reminderLabel = '${digest.hoursBeforeCheckIn}h antes do check-in';

    return _PlanSectionCard(
      title: 'Resumo automático de bem-estar',
      description: 'Receba um aviso com metas, hidratação e recomendações antes de registrar o peso.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.notifications_active_outlined,
                label: 'Próximo aviso',
                value: reminderLabel,
              ),
              _InfoChip(
                icon: Icons.flag_outlined,
                label: 'Objetivo do ciclo',
                value: plan.profile.goal.label,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (digest.summary.isNotEmpty)
            Text(
              digest.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...highlights.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.brightness_1,
                        size: 10,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (digest.callToAction.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              digest.callToAction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _HydrationReminderTile extends StatelessWidget {
  const _HydrationReminderTile({required this.slot});

  final HydrationReminderSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${slot.formattedTime} · ${slot.amountMl} ml',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFocusCard extends StatelessWidget {
  const _DailyFocusCard({
    required this.controller,
    required this.plan,
  });

  final NutritionPlanController controller;
  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = controller.todayProgressInfo;
    if (info == null) {
      return const SizedBox.shrink();
    }
    final coach = controller.dailyCoachMessage;
    final completionPercent = (info.completionRatio * 100).clamp(0, 100).round();
    final caloriesLabel = info.targetCalories <= 0
        ? '${info.consumedCalories} kcal estimadas'
        : '${info.consumedCalories} / ${info.targetCalories} kcal';
    final caloriesRemaining = info.targetCalories <= 0
        ? null
        : info.targetCalories - info.consumedCalories;
    final caloriesSubtitle = info.targetCalories <= 0
        ? 'Ajuste o questionário para estimar sua meta calórica.'
        : caloriesRemaining != null && caloriesRemaining <= 0
            ? 'Meta diária atingida.'
            : 'Faltam ${caloriesRemaining!.clamp(0, info.targetCalories)} kcal para a meta.';
    final mealProgress = info.totalMeals == 0 ? 0.0 : info.completedMeals / info.totalMeals;
    final pendingLabel = info.totalMeals == 0
        ? 'Nenhuma refeição cadastrada hoje.'
        : info.pendingMeals == 0
            ? 'Dia concluído!'
            : '${info.pendingMeals} refeição(ões) aguardando registro.';

    final macroTargets = info.macroTargets;
    final consumedMacros = info.consumedMacros;
    final macroWidgets = <Widget>[];
    const labels = <String, String>{
      'carbs': 'Carboidratos',
      'proteins': 'Proteínas',
      'fats': 'Gorduras',
    };
    const colors = <String, Color>{
      'carbs': Colors.orangeAccent,
      'proteins': Colors.green,
      'fats': Colors.purpleAccent,
    };
    macroTargets.forEach((key, target) {
      final label = labels[key];
      final color = colors[key];
      if (label != null && color != null) {
        macroWidgets.add(
          _DailyMacroIndicator(
            label: label,
            consumed: consumedMacros[key] ?? 0,
            target: target,
            color: color,
          ),
        );
      }
    });

    return _PlanSectionCard(
      title: 'Resumo do dia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dia em andamento: ${info.dayLabel}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            info.dayFocus,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Progresso de hoje',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: info.completionRatio.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completionPercent% do dia concluído',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final children = <Widget>[
                Expanded(
                  child: _DailyMetricTile(
                    label: 'Calorias estimadas',
                    value: caloriesLabel,
                    subtitle: caloriesSubtitle,
                    progress: info.targetCalories <= 0
                        ? 0
                        : (info.consumedCalories / info.targetCalories).clamp(0.0, 1.2),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DailyMetricTile(
                    label: 'Refeições do dia',
                    value: '${info.completedMeals}/${info.totalMeals} concluídas',
                    subtitle: pendingLabel,
                    progress: info.totalMeals == 0 ? 0 : mealProgress.clamp(0.0, 1.0),
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ];
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    children[0],
                    const SizedBox(height: 12),
                    children[2],
                  ],
                );
              }
              return Row(children: children);
            },
          ),
          const SizedBox(height: 16),
          _DailyCoachBanner(message: coach),
          if (macroWidgets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Distribuição estimada de macros',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: macroWidgets,
            ),
          ],
          if (plan.plan.hydrationGoal.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              plan.plan.hydrationGoal,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyMetricTile extends StatelessWidget {
  const _DailyMetricTile({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMacroIndicator extends StatelessWidget {
  const _DailyMacroIndicator({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTarget = target > 0;
    final ratio = hasTarget ? (consumed / target).clamp(0.0, 1.2) : 0.0;
    final displayValue = hasTarget
        ? '${consumed.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} g'
        : '${consumed.toStringAsFixed(1)} g';
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_dining_outlined, color: color),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCoachBanner extends StatelessWidget {
  const _DailyCoachBanner({required this.message});

  final DailyCoachMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final Color color;
    late final IconData icon;
    switch (message.tone) {
      case DailyCoachTone.success:
        color = Colors.green;
        icon = Icons.celebration_outlined;
        break;
      case DailyCoachTone.caution:
        color = Colors.orangeAccent;
        icon = Icons.flag_outlined;
        break;
      case DailyCoachTone.info:
        color = theme.colorScheme.primary;
        icon = Icons.lightbulb_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface.withOpacity(0.75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: baseColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverviewCard extends StatelessWidget {
  const _ProgressOverviewCard({
    required this.controller,
    required this.plan,
  });

  final NutritionPlanController controller;
  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = controller.overallCompletionRatio().clamp(0.0, 1.0);
    final ratioLabel = '${(ratio * 100).round()}% das refeições concluídas';
    final elapsed = DateTime.now().difference(plan.generatedAt);
    final total = plan.profile.interval.duration;
    final cycleProgress = total.inMinutes == 0
        ? 0.0
        : (elapsed.inMinutes / total.inMinutes).clamp(0.0, 1.2);

    final delta = plan.lastWeighInKg - plan.startingWeightKg;
    String? alertTitle;
    String? alertMessage;
    Color? alertColor;

    if (plan.needsAdjustment) {
      alertTitle = 'Revisão necessária';
      alertMessage =
          'O último check-in indicou que o ritmo não está ideal. Vamos propor ajustes automáticos no próximo cardápio.';
      alertColor = theme.colorScheme.error;
    } else if (plan.profile.goal == DietGoal.loseWeight && delta >= 0.1) {
      alertTitle = 'Olho no objetivo';
      alertMessage =
          'O peso ainda não começou a cair. Reforce hidratação, descanso e registre o consumo diário para que possamos adaptar o plano.';
      alertColor = Colors.orangeAccent;
    } else if (ratio < 0.45 && cycleProgress > 0.4) {
      alertTitle = 'Que tal avançar um pouco mais?';
      alertMessage =
          'Estamos na metade do ciclo e menos da metade das refeições foram concluídas. Use o diário para registrar ajustes ou substituições.';
      alertColor = Colors.orangeAccent;
    } else if (ratio > 0.85 && cycleProgress < 0.5) {
      alertTitle = 'Excelente ritmo!';
      alertMessage =
          'Você está adiantado no cardápio. Continue registrando o consumo para personalizarmos ainda mais as próximas semanas.';
      alertColor = theme.colorScheme.secondary;
    }

    return _PlanSectionCard(
      title: 'Acompanhamento em tempo real',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progresso geral do ciclo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: ratio,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ratioLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (alertTitle != null && alertMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (alertColor ?? theme.colorScheme.primary)
                    .withOpacity(alertColor == theme.colorScheme.error ? 0.12 : 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    alertColor == theme.colorScheme.error
                        ? Icons.warning_amber_outlined
                        : Icons.insights_outlined,
                    color: alertColor ?? theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alertTitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: alertColor ?? theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alertMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _WeightTrendChart(plan: plan),
        ],
      ),
    );
  }
}

class _WeightTrendChart extends StatelessWidget {
  const _WeightTrendChart({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = plan.weightHistory.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Registre pelo menos dois pesos para visualizar a evolução.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final start = entries.first;
    final end = entries.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CustomPaint(
              painter: _WeightTrendPainter(
                entries: entries,
                color: theme.colorScheme.primary,
                baseline: plan.startingWeightKg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Início: ${start.weightKg.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Atual: ${end.weightKg.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  _WeightTrendPainter({
    required this.entries,
    required this.color,
    required this.baseline,
  });

  final List<WeightEntry> entries;
  final Color color;
  final double baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    if (entries.isEmpty) {
      return;
    }

    final weights = entries.map((e) => e.weightKg).toList();
    var minWeight = weights.reduce(math.min);
    var maxWeight = weights.reduce(math.max);
    if ((maxWeight - minWeight).abs() < 0.1) {
      maxWeight += 0.5;
      minWeight -= 0.5;
    }
    final span = maxWeight - minWeight;
    final verticalPadding = 16.0;
    final chartHeight = size.height - verticalPadding * 2;

    final points = <Offset>[];
    for (var i = 0; i < entries.length; i++) {
      final weight = entries[i].weightKg;
      final x = entries.length == 1
          ? size.width / 2
          : (i / (entries.length - 1)) * size.width;
      final normalized = (weight - minWeight) / span;
      final y = size.height - verticalPadding - (normalized * chartHeight);
      points.add(Offset(x, y));
    }

    final gridPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - verticalPadding),
      Offset(size.width, size.height - verticalPadding),
      gridPaint,
    );

    final baselineNormalized = ((baseline - minWeight) / span)
        .clamp(0.0, 1.0);
    final baselineY = size.height - verticalPadding - (baselineNormalized * chartHeight);
    final baselinePaint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.color != color ||
        oldDelegate.baseline != baseline;
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
  const _PlanDaysView({
    required this.controller,
    required this.plan,
  });

  final NutritionPlanController controller;
  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PlanSectionCard(
      title: 'Agenda de refeições',
      child: Column(
        children: plan.plan.days
            .asMap()
            .entries
            .map(
              (entry) => _PlanDayTile(
                controller: controller,
                plan: plan,
                dayIndex: entry.key,
                day: entry.value,
                targets: plan.plan.targets,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PlanDayTile extends StatelessWidget {
  const _PlanDayTile({
    required this.controller,
    required this.plan,
    required this.dayIndex,
    required this.day,
    required this.targets,
  });

  final NutritionPlanController controller;
  final NutritionPlan plan;
  final int dayIndex;
  final DietPlanDay day;
  final DietPlanTargets targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMeals = day.meals.length;
    final completionRatio = controller.dayCompletionRatio(dayIndex).clamp(0.0, 1.0);
    final completionLabel = controller.dayCompletionLabel(dayIndex);
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
            if (totalMeals > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completionLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: completionRatio,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
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
            _PlanMealTile(
              controller: controller,
              dayIndex: dayIndex,
              mealIndex: i,
              day: day,
              meal: day.meals[i],
            ),
            if (i < day.meals.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class _PlanMealTile extends StatelessWidget {
  const _PlanMealTile({
    required this.controller,
    required this.dayIndex,
    required this.mealIndex,
    required this.day,
    required this.meal,
  });

  final NutritionPlanController controller;
  final int dayIndex;
  final int mealIndex;
  final DietPlanDay day;
  final DietPlanMeal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = controller.isMealCompleted(dayIndex, mealIndex);
    final isLoading = controller.isMealLoading(dayIndex, mealIndex);
    final contentOpacity = isCompleted ? 0.7 : 1.0;
    final portion = controller.mealPortionFactor(dayIndex, mealIndex).clamp(0.0, 1.5);
    final note = controller.mealNote(dayIndex, mealIndex);

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
            SizedBox(
              width: 36,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Checkbox(
                        value: isCompleted,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) =>
                            controller.toggleMealCompletion(dayIndex, mealIndex),
                      ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.restaurant_menu,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: contentOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
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
        if (portion > 0 || (note != null && note.trim().isNotEmpty)) ...[
          const SizedBox(height: 12),
          _MealProgressSummary(portion: portion, note: note, theme: theme),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton.icon(
              onPressed: isLoading ? null : () => _openMealLogSheet(context),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Registrar consumo'),
            ),
            TextButton.icon(
              onPressed: () => controller.openMealInLaboratory(day, meal),
              icon: const Icon(Icons.biotech_outlined),
              label: const Text('Explorar no laboratório'),
            ),
            TextButton.icon(
              onPressed: () => _openRecipe(day, meal),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Ver receita completa'),
            ),
          ],
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

  Future<void> _openMealLogSheet(BuildContext context) async {
    final initialPortion = controller.mealPortionFactor(dayIndex, mealIndex).clamp(0.0, 1.5);
    final initialNote = controller.mealNote(dayIndex, mealIndex) ?? '';
    final portionNotifier = ValueNotifier<double>(initialPortion);
    final noteController = TextEditingController(text: initialNote);

    try {
      final result = await showModalBottomSheet<_MealLogResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _MealLogSheet(
          meal: meal,
          portion: portionNotifier,
          noteController: noteController,
        ),
      );

      if (result != null) {
        await controller.recordMealLog(
          dayIndex: dayIndex,
          mealIndex: mealIndex,
          portion: result.portion,
          notes: result.note,
        );
      }
    } finally {
      portionNotifier.dispose();
      noteController.dispose();
    }
  }
}

class _MealProgressSummary extends StatelessWidget {
  const _MealProgressSummary({
    required this.portion,
    required this.note,
    required this.theme,
  });

  final double portion;
  final String? note;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ratio = portion.clamp(0.0, 1.0);
    final label = portion <= 0
        ? 'Ainda não registrado'
        : portion >= 1
            ? 'Refeição concluída'
            : 'Consumido ~${(portion * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (note != null && note!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Observação: ${note!.trim()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ],
    );
  }
}

class _MealLogResult {
  const _MealLogResult({required this.portion, required this.note});

  final double portion;
  final String? note;
}

class _MealLogSheet extends StatelessWidget {
  const _MealLogSheet({
    required this.meal,
    required this.portion,
    required this.noteController,
  });

  final DietPlanMeal meal;
  final ValueNotifier<double> portion;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registrar consumo',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            meal.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<double>(
            valueListenable: portion,
            builder: (context, value, _) {
              final label = value <= 0
                  ? 'Não consumida'
                  : value >= 1
                      ? '100% consumida'
                      : '${(value * 100).round()}% consumidos';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quanto da refeição você consumiu?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Slider(
                    value: value,
                    min: 0,
                    max: 1.5,
                    divisions: 15,
                    label: label,
                    onChanged: (newValue) => portion.value = newValue,
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Ex.: ajustei o tempero, substituí por outra fruta...',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _MealLogResult(
                      portion: portion.value,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    ),
                  );
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
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

