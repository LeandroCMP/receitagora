import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/models/skill/skill_journey.dart';

import 'skill_journeys_controller.dart';

class SkillJourneysPage extends GetView<SkillJourneysController> {
  const SkillJourneysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trilhas de habilidades'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = AppPageLayout.resolve(
              constraints,
              maxWidth: 720,
              topPadding: 32,
              bottomPadding: 32,
            );
            final mediaQuery = MediaQuery.of(context);

            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: layout.textScaler),
              child: ListView.builder(
                padding: layout.padding,
                itemCount: controller.journeys.length,
                itemBuilder: (context, index) {
                  final journey = controller.journeys[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _JourneyCard(
                      theme: theme,
                      journey: journey,
                      onTap: () => controller.openJourney(journey),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.theme,
    required this.journey,
    required this.onTap,
  });

  final ThemeData theme;
  final SkillJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final durationHours = journey.totalDurationMinutes / 60;
    final durationFormatter = NumberFormat('#0.0');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      journey.focus,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    label: Text(journey.level),
                    avatar: const Icon(Icons.workspace_premium_outlined, size: 18),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                journey.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                journey.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text('${journey.steps.length} etapas'),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule_outlined, color: colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text('${durationFormatter.format(durationHours)} h'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
