import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';

import 'nutrition_plan_controller.dart';

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
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
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
                    Obx(
                      () {
                        final value = controller.metabolicEase.value;
                        return Column(
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
                              value: value,
                              min: 0,
                              max: 5,
                              divisions: 5,
                              label: value.round().toString(),
                              onChanged: locked
                                  ? null
                                  : (newValue) => controller.metabolicEase.value = newValue,
                            ),
                          ],
                        );
                      },
                    ),
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
                    const SizedBox(height: 12),
                    Obx(
                      () => SwitchListTile.adaptive(
                        value: controller.prefersBrazilianCuisine.value,
                        onChanged: locked ? null : controller.toggleBrazilianCuisine,
                        title: const Text('Priorizar sabores brasileiros'),
                        subtitle: const Text('Ative para privilegiar temperos e preparos nacionais.'),
                      ),
                    ),
                    Obx(
                      () => SwitchListTile.adaptive(
                        value: controller.prefersSeasonalProduce.value,
                        onChanged: locked ? null : controller.toggleSeasonalProduce,
                        title: const Text('Usar ingredientes sazonais'),
                        subtitle: const Text('Sugestões alinhadas à safra para economizar e ganhar sabor.'),
                      ),
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
                                onSelected: locked
                                    ? null
                                    : (_) => controller.setSnackFrequency(option),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
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
                    if (locked) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cardápio ativo. Use os botões da página principal para gerar uma nova variação ou escolha editar os dados para recalibrar o plano.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.75),
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

