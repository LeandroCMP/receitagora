import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';

import 'nutrition_plan_controller.dart';

class _MetabolismOption {
  const _MetabolismOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final int value;
  final String title;
  final String subtitle;
}

const List<_MetabolismOption> _metabolismOptions = <_MetabolismOption>[
  _MetabolismOption(
    value: 1,
    title: 'Tenho dificuldade para emagrecer',
    subtitle: 'Perco peso lentamente mesmo ajustando alimentação e rotina.',
  ),
  _MetabolismOption(
    value: 3,
    title: 'Metabolismo equilibrado',
    subtitle: 'Consigo manter ou alterar o peso com mudanças moderadas.',
  ),
  _MetabolismOption(
    value: 5,
    title: 'Metabolismo acelerado',
    subtitle: 'Reajo rápido aos ajustes de dieta ou treino.',
  ),
];

class NutritionPlanFormPage extends GetView<NutritionPlanController> {
  const NutritionPlanFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final background = surfaces?.lowest ?? theme.colorScheme.background;
    final args = Get.arguments;
    final editing = args is Map && args['editing'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Atualizar dados do plano' : 'Seu perfil nutricional'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withValues(alpha: 0.05),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chef nutricional da Receita Agora',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  editing
                      ? 'Revise suas informações para atualizar metas e cardápio.'
                      : 'Preencha o questionário para receber um cardápio equilibrado com metas calóricas, macros e lista de compras automática.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 32),
                _ProfileForm(controller: controller),
              ],
            ),
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
    return Obx(() {
      final locked = controller.isFormLocked.value;
      final isGenerating = controller.isGenerating.value;
      return _PlanSectionCard(
        title: 'Seu perfil metabólico',
        description:
            'Responda de forma sincera para que a IA calcule metas realistas e mantenha o cardápio adaptado ao seu ritmo.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: locked ? 0.55 : 1,
              child: AbsorbPointer(
                absorbing: locked,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResponsiveFieldRow(
                      children: [
                        _TextFieldItem(
                          controller: controller.heightController,
                          label: 'Altura (cm)',
                          hint: 'Ex.: 172',
                          enabled: !locked,
                        ),
                        _TextFieldItem(
                          controller: controller.weightController,
                          label: 'Peso atual (kg)',
                          hint: 'Ex.: 78.5',
                          enabled: !locked,
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
                      enabled: !locked,
                    ),
                    const SizedBox(height: 20),
                    _MetabolismSelector(controller: controller, locked: locked),
                    const SizedBox(height: 20),
                    _ChoiceSection<DietGoal>(
                      title: 'Objetivo principal',
                      description: 'O cardápio será calibrado para este foco.',
                      options: DietGoal.values,
                      selected: controller.goal,
                      labelBuilder: (goal) => goal.label,
                      onSelected: controller.setGoal,
                      enabled: !locked,
                    ),
                    const SizedBox(height: 20),
                    _ChoiceSection<DietPlanInterval>(
                      title: 'Frequência do plano',
                      description: 'Prefere cardápio semanal ou mensal?',
                      options: DietPlanInterval.values,
                      selected: controller.interval,
                      labelBuilder: (value) => value.label,
                      onSelected: controller.setInterval,
                      enabled: !locked,
                    ),
                    const SizedBox(height: 20),
                    _ChoiceSection<DietCookingStyle>(
                      title: 'Modo de preparo',
                      description: 'Defina se cozinha diariamente ou prefere preparar e congelar.',
                      options: DietCookingStyle.values,
                      selected: controller.cookingStyle,
                      labelBuilder: (value) => value.label,
                      onSelected: controller.setCookingStyle,
                      enabled: !locked,
                    ),
                    const SizedBox(height: 20),
                    _DynamicRecommendationBanner(controller: controller, locked: locked),
                    const SizedBox(height: 20),
                    _OptionalPreferences(controller: controller, locked: locked),
                    if (locked) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cardápio ativo. Use os botões da página principal para gerar uma nova variação ou escolha editar os dados para recalibrar o plano.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ButtonItem(
              label: locked
                  ? 'Plano ativo'
                  : isGenerating
                      ? 'Gerando...'
                      : 'Gerar cardápio personalizado',
              icon: locked
                  ? Icons.lock_outline
                  : isGenerating
                      ? Icons.dining_outlined
                      : Icons.auto_fix_high_outlined,
              isLoading: isGenerating,
              onPressed: locked || isGenerating ? null : controller.generatePlan,
            ),
          ],
        ),
      );
    });
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
    this.enabled = true,
  });

  final String title;
  final String description;
  final List<T> options;
  final Rx<T> selected;
  final String Function(T value) labelBuilder;
  final void Function(T value) onSelected;
  final bool enabled;

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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    onSelected: enabled ? (_) => onSelected(option) : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MetabolismSelector extends StatelessWidget {
  const _MetabolismSelector({
    required this.controller,
    required this.locked,
  });

  final NutritionPlanController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ritmo do metabolismo',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolha a opção que melhor descreve como seu corpo reage às dietas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () {
            final selected = controller.metabolicEase.value;
            return Column(
              children: _metabolismOptions
                  .map(
                    (option) => RadioListTile<int>(
                      value: option.value,
                      groupValue: selected,
                      onChanged: locked
                          ? null
                          : (value) {
                              if (value != null) {
                                controller.metabolicEase.value = value;
                              }
                            },
                      title: Text(option.title),
                      subtitle: Text(
                        option.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DynamicRecommendationBanner extends StatelessWidget {
  const _DynamicRecommendationBanner({
    required this.controller,
    required this.locked,
  });

  final NutritionPlanController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final hints = <String>[];
      final goal = controller.goal.value;
      final activity = controller.activityLevel.value;
      final cooking = controller.cookingStyle.value;
      final metabolism = controller.metabolicEase.value;
      final snacks = controller.snackFrequency.value;

      switch (goal) {
        case DietGoal.loseWeight:
          hints.add('Priorize proteínas magras no almoço e jantar e evite grandes intervalos sem comer.');
          break;
        case DietGoal.gainMass:
          hints.add('Inclua carboidratos complexos e um lanche calórico pós-treino para sustentar o ganho de massa.');
          break;
        case DietGoal.maintain:
          hints.add('Equilibre porções e distribua as calorias ao longo do dia para manter o peso com conforto.');
          break;
        case DietGoal.reeducate:
          hints.add('Varie texturas e cores no prato para facilitar a reeducação alimentar e aumentar saciedade.');
          break;
      }

      switch (activity) {
        case DietActivityLevel.sedentary:
          hints.add('Inclua caminhadas leves ou alongamentos diários para ativar o metabolismo e melhorar o sono.');
          break;
        case DietActivityLevel.light:
          hints.add('Combine exercícios leves com hidratação constante para aproveitar ao máximo o cardápio.');
          break;
        case DietActivityLevel.moderate:
          hints.add('Planeje lanches ricos em proteínas nos dias de treino para evitar quedas de energia.');
          break;
        case DietActivityLevel.intense:
          hints.add('Garanta reposição de carboidratos complexos após treinos intensos para recuperar a musculatura.');
          break;
      }

      if (metabolism <= 2) {
        hints.add('Metabolismo mais lento: use fibras e proteínas em todas as refeições para controlar fome e açúcar.');
      } else if (metabolism >= 4) {
        hints.add('Metabolismo acelerado: programe lanches energéticos para não pular refeições sem perceber.');
      }

      if (cooking == DietCookingStyle.batchAndFreeze) {
        hints.add('Reserve um dia da semana para preparar e congelar porções equilibradas, facilitando a adesão.');
      } else {
        hints.add('Mantenha ingredientes frescos por perto para montar pratos rápidos e variados diariamente.');
      }

      if (snacks.toLowerCase().contains('alta')) {
        hints.add('Ajuste os lanches para opções ricas em fibras e gorduras boas, evitando picos de açúcar.');
      }

      if (hints.isEmpty) {
        return const SizedBox.shrink();
      }

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: locked ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Sugestões do chef nutricional',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...hints.map(
                (hint) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          hint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
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

class _OptionalPreferences extends StatelessWidget {
  const _OptionalPreferences({
    required this.controller,
    required this.locked,
  });

  final NutritionPlanController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expansionTheme = theme.copyWith(dividerColor: Colors.transparent);

    return Theme(
      data: expansionTheme,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 4),
        title: const Text('Preferências opcionais'),
        subtitle: Text(
          'Ajuste sabores, lanches e recados se quiser personalizar ainda mais.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        children: [
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.prefersBrazilianCuisine.value,
              onChanged: locked ? null : controller.toggleBrazilianCuisine,
              title: const Text('Priorizar sabores brasileiros'),
              subtitle: const Text('Prefira temperos e combinações nacionais sempre que possível.'),
            ),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.prefersSeasonalProduce.value,
              onChanged: locked ? null : controller.toggleSeasonalProduce,
              title: const Text('Valorizar ingredientes sazonais'),
              subtitle: const Text('Sugestões alinhadas à safra para economizar e ganhar sabor.'),
            ),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.hydrationCoachEnabled.value,
              onChanged: locked ? null : controller.toggleHydrationCoach,
              title: const Text('Lembretes automáticos de hidratação'),
              subtitle: const Text('Receba metas calculadas e alertas ao longo do dia.'),
            ),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.mindfulBreaksEnabled.value,
              onChanged: locked ? null : controller.toggleMindfulBreaks,
              title: const Text('Pausa de bem-estar guiada'),
              subtitle: const Text('Um lembrete diário para alongar, respirar e cuidar da postura.'),
            ),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.movementCoachEnabled.value,
              onChanged: locked ? null : controller.toggleMovementCoach,
              title: const Text('Pausas ativas automáticas'),
              subtitle: const Text('Receba lembretes de alongamentos rápidos ao longo do dia.'),
            ),
          ),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.sunlightCoachEnabled.value,
              onChanged: locked ? null : controller.toggleSunlightCoach,
              title: const Text('Rotina de luz natural'),
              subtitle: const Text('Agenda um lembrete diário para tomar sol com segurança.'),
            ),
          ),
          Obx(() {
            final enabled = controller.sleepCoachEnabled.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  value: enabled,
                  onChanged: locked ? null : controller.toggleSleepCoach,
                  title: const Text('Aviso para desacelerar antes de dormir'),
                  subtitle: const Text('Receba um lembrete 30 minutos antes do horário ideal de sono.'),
                ),
                if (enabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NutritionPlanController.sleepOptions
                          .map(
                            (option) => ChoiceChip(
                              label: Text(option.label),
                              selected: controller.sleepWindow.value == option,
                              onSelected: locked
                                  ? null
                                  : (_) => controller.setSleepWindow(option),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            );
          }),
          Obx(
            () => SwitchListTile.adaptive(
              value: controller.wellnessDigestEnabled.value,
              onChanged: locked ? null : controller.toggleWellnessDigest,
              title: const Text('Resumo automático de bem-estar'),
              subtitle: const Text('Receba um lembrete antes do check-in com destaques da semana.'),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Frequência de lanches',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
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
                      onSelected: locked
                          ? null
                          : (_) => controller.setSnackFrequency(option),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.notesController,
            maxLines: 4,
            enabled: !locked,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Observações adicionais',
              hintText: 'Restrições médicas, utensílios disponíveis, preferências familiares...',
            ),
          ),
          const SizedBox(height: 8),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                children[i],
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

abstract class _FormRowChild extends StatelessWidget {
  const _FormRowChild({super.key});
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

