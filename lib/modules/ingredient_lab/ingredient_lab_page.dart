import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/models/ingredient_lab/ingredient_lab_report.dart';

import 'ingredient_lab_controller.dart';

class IngredientLabPage extends GetView<IngredientLabController> {
  const IngredientLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();
    final background = surfaces?.lowest ?? theme.colorScheme.background;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratório de ingredientes'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.secondary.withValues(alpha: 0.05),
                background,
              ),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              return Obx(
                () {
                  final report = controller.report.value;
                  final isRunning = controller.isRunning.value;

                  final form = _IngredientLabForm(
                    controller: controller,
                    isRunning: isRunning,
                  );

                  final results = _IngredientLabResultSection(report: report);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Chef IA do Laboratório',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Descreva o ingrediente, o contexto e o objetivo da troca. A IA organiza alternativas viáveis, '
                          'ajustes de preparo, alertas e uma lista de compras rápida.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: form),
                              const SizedBox(width: 32),
                              Expanded(flex: 4, child: results),
                            ],
                          )
                        else ...[
                          form,
                          const SizedBox(height: 24),
                          results,
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

class _IngredientLabForm extends StatelessWidget {
  const _IngredientLabForm({
    required this.controller,
    required this.isRunning,
  });

  final IngredientLabController controller;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _LabSectionCard(
      title: 'Briefing do ingrediente',
      description:
          'Conte quais ingredientes possui, o motivo da troca e qualquer limitação. Quanto mais contexto, melhor a recomendação.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveTextFields(
            fields: [
              _LabTextFieldConfig(
                label: 'Ingrediente alvo',
                controller: controller.ingredientController,
                hintText: 'Queijo parmesão, manteiga sem sal, ovo... ',
              ),
              _LabTextFieldConfig(
                label: 'Receita ou contexto',
                controller: controller.contextController,
                hintText: 'Molho branco, bolo de cenoura, farofa crocante...',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Objetivo da substituição',
            helper: 'Explique o resultado desejado: reduzir lactose, ganhar crocância, aumentar proteínas etc.',
            child: TextField(
              controller: controller.goalController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Manter textura sem lactose, deixar mais leve para congelar...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _EditableChips(
            title: 'Ingredientes disponíveis',
            helper:
                'Liste o que já tem em mãos ou compra facilmente. O laboratório prioriza alternativas que cabem nesse inventário.',
            items: controller.availableItems,
            controller: controller.availableInputController,
            onAdd: controller.addAvailableItem,
            onRemove: controller.removeAvailableItem,
          ),
          const SizedBox(height: 16),
          _EditableChips(
            title: 'Restrições e alergias',
            helper: 'Inclua alergias, aversões ou ingredientes proibidos. As restrições do perfil são herdadas automaticamente.',
            items: controller.restrictedItems,
            controller: controller.restrictionInputController,
            onAdd: controller.addRestriction,
            onRemove: controller.removeRestriction,
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: 'Observações adicionais',
            helper: 'Cite utensílios disponíveis, preferências de sabor ou limitações de tempo.',
            child: TextField(
              controller: controller.notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Tenho air fryer, prefiro sabores defumados e pouco picantes.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isRunning ? null : controller.runLaboratory,
              icon: isRunning
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.science_outlined),
              label: Text(isRunning ? 'Analisando ingrediente...' : 'Rodar laboratório'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientLabResultSection extends StatelessWidget {
  const _IngredientLabResultSection({required this.report});

  final IngredientLabReport? report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report == null) {
      return _LabSectionCard(
        title: 'Resultado do laboratório',
        child: _EmptyState(theme: theme),
      );
    }

    final hasHighlights = report!.highlights.isNotEmpty;
    final hasWarnings = report!.hasWarnings;
    final hasShopping = report!.hasShoppingSuggestions;

    return _LabSectionCard(
      title: report!.ingredient,
      description: report!.roleSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHighlights) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: report!.highlights
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      avatar: Icon(
                        Icons.local_fire_department_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Substituições recomendadas',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...report!.alternatives.map((alt) => _AlternativeTile(alternative: alt)),
          if (report!.techniqueTips.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Técnicas sugeridas',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...report!.techniqueTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
          ],
          if (hasWarnings) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.error.withValues(alpha: 0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report!.warnings
                    .map(
                      (warning) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                warning,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (hasShopping) ...[
            const SizedBox(height: 24),
            Text(
              'Sugestões para as compras',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...report!.shoppingSuggestions.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shopping_basket_outlined, color: theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item)),
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

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.alternative});

  final IngredientLabAlternative alternative;

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
        title: Text(alternative.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          alternative.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        children: [
          if (alternative.ratio.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.scale_outlined, color: theme.colorScheme.primary),
              title: Text('Proporção sugerida: ${alternative.ratio}'),
            ),
          if (alternative.adjustments.isNotEmpty)
            _BulletSection(
              icon: Icons.restaurant_menu,
              color: theme.colorScheme.primary,
              title: 'Ajustes de preparo',
              items: alternative.adjustments,
            ),
          if (alternative.idealUses.isNotEmpty)
            _BulletSection(
              icon: Icons.lightbulb_outline,
              color: theme.colorScheme.secondary,
              title: 'Melhor uso',
              items: alternative.idealUses,
            ),
          if (alternative.cautions.isNotEmpty)
            _BulletSection(
              icon: Icons.report_problem_outlined,
              color: theme.colorScheme.error,
              title: 'Atenção',
              items: alternative.cautions,
            ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableChips extends StatelessWidget {
  const _EditableChips({
    required this.title,
    required this.helper,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String helper;
  final RxList<String> items;
  final TextEditingController controller;
  final void Function([String? value]) onAdd;
  final void Function(String value) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Digite e pressione Enter para adicionar',
                ),
                onSubmitted: onAdd,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: FilledButton(
                onPressed: () => onAdd(),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () {
            if (items.isEmpty) {
              return Text(
                'Nenhum item informado ainda.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => InputChip(
                      label: Text(item),
                      onDeleted: () => onRemove(item),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    this.helper,
    required this.child,
  });

  final String label;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ResponsiveTextFields extends StatelessWidget {
  const _ResponsiveTextFields({required this.fields});

  final List<_LabTextFieldConfig> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumns = constraints.maxWidth >= 520 && fields.length > 1;
        if (!isTwoColumns) {
          return Column(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                _LabeledField(
                  label: fields[i].label,
                  child: TextField(
                    controller: fields[i].controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: fields[i].hintText),
                  ),
                ),
                if (i != fields.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        final left = <_LabTextFieldConfig>[];
        final right = <_LabTextFieldConfig>[];
        for (var i = 0; i < fields.length; i++) {
          (i.isEven ? left : right).add(fields[i]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ResponsiveTextFields(fields: left)),
            const SizedBox(width: 16),
            Expanded(child: _ResponsiveTextFields(fields: right)),
          ],
        );
      },
    );
  }
}

class _LabTextFieldConfig {
  const _LabTextFieldConfig({
    required this.label,
    required this.controller,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
}

class _LabSectionCard extends StatelessWidget {
  const _LabSectionCard({
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Assim que rodar o laboratório, você verá as melhores substituições com ajustes de preparo, alertas e dicas de compra.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
