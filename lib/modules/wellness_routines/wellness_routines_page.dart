import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';

import 'wellness_routines_controller.dart';

class WellnessRoutinesPage extends GetView<WellnessRoutinesController> {
  const WellnessRoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotinas de bem-estar'),
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 720,
                topPadding: 28,
                bottomPadding: 32,
              );

              final mediaQuery = MediaQuery.of(context);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: layout.textScaler),
                child: Obx(() {
                  final routines = controller.routines.toList();
                  final enabled = controller.enabled;

                  return SingleChildScrollView(
                    padding: layout.padding,
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: layout.maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WellnessIntroCard(theme: theme, surfaces: surfaces),
                            const SizedBox(height: 24),
                            ...routines.map(
                              (routine) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _WellnessRoutineCard(
                                  theme: theme,
                                  surfaces: surfaces,
                                  routine: routine,
                                  enabled: enabled.contains(routine.id),
                                  onChanged: (value) async {
                                    await controller.toggleRoutine(routine, value);
                                    AppSnackbar.info(
                                      title: value
                                          ? 'Rotina ativada'
                                          : 'Rotina desativada',
                                      message: value
                                          ? 'Os lembretes dessa rotina foram programados.'
                                          : 'Os lembretes desta rotina foram cancelados.',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WellnessIntroCard extends StatelessWidget {
  const _WellnessIntroCard({required this.theme, required this.surfaces});

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.85),
            (surfaces?.surface ?? colorScheme.surfaceVariant).withOpacity(0.9),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha uma jornada de hábitos saudáveis',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ative combinações de lembretes que equilibram hidratação, movimento, foco e descanso sem sobrecarregar seu dia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellnessRoutineCard extends StatelessWidget {
  const _WellnessRoutineCard({
    required this.theme,
    required this.surfaces,
    required this.routine,
    required this.enabled,
    required this.onChanged,
  });

  final ThemeData theme;
  final ReceitagoraSurfaceColors? surfaces;
  final WellnessRoutine routine;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        routine.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.72),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: onChanged,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: (surfaces?.surface ?? colorScheme.surfaceVariant)
                    .withOpacity(0.55),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: routine.highlights
                      .map(
                        (highlight) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  highlight,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.75),
                                    height: 1.4,
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
            ),
          ],
        ),
      ),
    );
  }
}
