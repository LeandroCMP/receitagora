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
                theme.colorScheme.secondary.withOpacity(0.05),
                background,
              ),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(
            () {
              final report = controller.report.value;
              final isRunning = controller.isRunning.value;
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
                      'Descreva o ingrediente que deseja substituir, os recursos disponíveis e o objetivo da troca. '
                      'O laboratório cruza suas preferências com alternativas confiáveis e entrega ajustes para a receita.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _IngredientLabForm(controller: controller, isRunning: isRunning),
                    if (report != null) ...[
                      const SizedBox(height: 36),
                      _IngredientLabReportView(report: report),
                    ] else ...[
                      const SizedBox(height: 24),
                      _EmptyState(theme: theme),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabeledField(
              label: 'Ingrediente alvo',
              child: TextField(
                controller: controller.ingredientController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Queijo parmesão, manteiga sem sal, ovo... ',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Receita ou contexto',
              helper: 'Opcional, mas ajuda o chef IA a entender a função do ingrediente.',
              child: TextField(
                controller: controller.contextController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Molho branco para massa, bolo de cenoura, farofa crocante...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Objetivo da substituição',
              helper: 'Explique o que você espera: manter crocância, reduzir lactose, aumentar proteínas etc.',
              child: TextField(
                controller: controller.goalController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Manter textura sem lactose, deixar mais leve para congelar...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _EditableChips(
              title: 'Ingredientes disponíveis',
              helper:
                  'Liste o que você já tem ou consegue comprar facilmente. Isso orienta o laboratório a priorizar substituições viáveis.',
              items: controller.availableItems,
              controller: controller.availableInputController,
              onAdd: controller.addAvailableItem,
              onRemove: controller.removeAvailableItem,
            ),
            const SizedBox(height: 16),
            _EditableChips(
              title: 'Restrições e alergias',
              helper:
                  'Inclua alergias, aversões ou ingredientes que não quer usar. As alergias do seu perfil já aparecem aqui automaticamente.',
              items: controller.restrictedItems,
              controller: controller.restrictionInputController,
              onAdd: controller.addRestriction,
              onRemove: controller.removeRestriction,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Observações adicionais',
              helper: 'Compartilhe detalhes extras como utensílios disponíveis ou preferências de sabor.',
              child: TextField(
                controller: controller.notesController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex.: Tenho air fryer, prefiro sabores defumados e pouco picantes.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
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
          ],
        ),
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
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Digite e pressione Enter para adicionar',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onAdd(),
            ),
          ),
          onSubmitted: onAdd,
        ),
        const SizedBox(height: 12),
        Obx(
          () {
            if (items.isEmpty) {
              return Text(
                'Nenhum item informado ainda.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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

class _IngredientLabReportView extends StatelessWidget {
  const _IngredientLabReportView({required this.report});

  final IngredientLabReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              report.ingredient,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.roleSummary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            if (report.highlights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.highlights
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        avatar: Icon(Icons.local_fire_department_outlined,
                            color: theme.colorScheme.primary, size: 18),
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.08),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Substituições recomendadas',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...report.alternatives.map((alternative) => _AlternativeTile(alternative: alternative)),
            const SizedBox(height: 24),
            if (report.techniqueTips.isNotEmpty) ...[
              Text(
                'Técnicas sugeridas',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...report.techniqueTips
                  .map(
                    (tip) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline,
                          color: theme.colorScheme.primary),
                      title: Text(tip),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 16),
            ],
            if (report.hasWarnings) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.error.withOpacity(0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.warnings
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_outlined,
                                  color: theme.colorScheme.error, size: 20),
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
              const SizedBox(height: 16),
            ],
            if (report.hasShoppingSuggestions) ...[
              Text(
                'Sugestões para as compras',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...report.shoppingSuggestions
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.shopping_basket_outlined,
                          color: theme.colorScheme.secondary),
                      title: Text(item),
                    ),
                  )
                  .toList(),
            ],
          ],
        ),
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
            color: theme.colorScheme.onSurface.withOpacity(0.7),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Quando o relatório for gerado, as melhores substituições aparecerão aqui com ajustes de preparo, avisos e dicas de compra.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
