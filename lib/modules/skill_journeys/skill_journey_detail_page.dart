import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';

import 'skill_journey_detail_controller.dart';

class SkillJourneyDetailPage extends GetView<SkillJourneyDetailController> {
  const SkillJourneyDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da trilha'),
      ),
      body: SafeArea(
        child: Obx(() {
          final journey = controller.journey.value;
          if (journey == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Não encontramos a trilha selecionada. Tente voltar e escolher outra opção.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }

          final durationHours = journey.totalDurationMinutes / 60;
          final durationFormatter = NumberFormat('#0.0');

          return LayoutBuilder(
            builder: (context, constraints) {
              final layoutValues = AppPageLayout.resolve(
                constraints,
                maxWidth: 720,
                topPadding: 32,
                bottomPadding: 48,
              );
              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layoutValues.textScaler),
                child: SingleChildScrollView(
                  padding: layoutValues.padding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: layoutValues.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            journey.title,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            journey.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _InfoChip(
                                icon: Icons.track_changes_outlined,
                                label: journey.focus,
                                color: theme.colorScheme.primary,
                              ),
                              _InfoChip(
                                icon: Icons.workspace_premium_outlined,
                                label: journey.level,
                                color: theme.colorScheme.secondary,
                              ),
                              _InfoChip(
                                icon: Icons.schedule_outlined,
                                label: '${durationFormatter.format(durationHours)} h no total',
                                color: theme.colorScheme.tertiary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Etapas da jornada',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          ...List<Widget>.generate(journey.steps.length, (index) {
                            final step = journey.steps[index];
                            final order = index + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _JourneyStepCard(
                                index: order,
                                title: step.title,
                                description: step.description,
                                durationMinutes: step.durationMinutes,
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () {
                              AppSnackbar.success(
                                title: 'Trilha adicionada',
                                message: 'Vamos lembrar você de consultar esta trilha nas próximas descobertas.',
                              );
                            },
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Marcar como próxima prática'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _JourneyStepCard extends StatelessWidget {
  const _JourneyStepCard({
    required this.index,
    required this.title,
    required this.description,
    required this.durationMinutes,
  });

  final int index;
  final String title;
  final String description;
  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 6),
                Text('$durationMinutes min de prática'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
