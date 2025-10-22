import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/models/subscription_plan.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/usage/app_usage_service.dart';
import 'package:receitagora/services/skill/skill_journey_service.dart';
import 'package:receitagora/services/wellness/wellness_routine_service.dart';
import 'package:receitagora/services/wellness/mood_journal_service.dart';

import 'user_profile_controller.dart';

class UserProfilePage extends GetView<UserProfileController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return Obx(() {
      final onboarding = controller.isOnboarding.value;
      final isSaving = controller.isSaving.value;
      return WillPopScope(
        onWillPop: () async => !onboarding,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !onboarding,
            leading: onboarding ? const SizedBox.shrink() : null,
            title: Text(onboarding ? 'Complete seu perfil' : 'Perfil'),
            actions: onboarding
                ? [
                    TextButton(
                      onPressed:
                          isSaving ? null : controller.completeOnboardingWithoutChanges,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Text('Continuar depois'),
                    ),
                  ]
                : null,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    theme.colorScheme.primary.withOpacity(0.05),
                    surfaces?.lowest ?? background,
                  ),
                  background,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = AppPageLayout.resolve(
                    constraints,
                    maxWidth: 640,
                    topPadding: 32,
                    bottomPadding: 32,
                  );

                  final mediaQuery = MediaQuery.of(context);

                  return MediaQuery(
                    data: mediaQuery.copyWith(textScaler: layout.textScaler),
                    child: SingleChildScrollView(
                      padding: layout.padding,
                      physics: const BouncingScrollPhysics(),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: layout.maxContentWidth),
                          child: _ProfileContent(
                            theme: theme,
                            controller: controller,
                            isOnboarding: onboarding,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.theme,
    required this.controller,
    required this.isOnboarding,
  });

  final ThemeData theme;
  final UserProfileController controller;
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final usageService =
        Get.isRegistered<AppUsageService>() ? Get.find<AppUsageService>() : null;
    final wellnessService = Get.isRegistered<WellnessRoutineService>()
        ? Get.find<WellnessRoutineService>()
        : null;
    final moodJournalService = Get.isRegistered<MoodJournalService>()
        ? Get.find<MoodJournalService>()
        : null;
    final skillJourneyService = Get.isRegistered<SkillJourneyService>()
        ? Get.find<SkillJourneyService>()
        : null;

    if (user == null) {
      return Center(
        child: Text(
          'Nenhum usuário autenticado.',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        if (isOnboarding) ...[
          _OnboardingNotice(theme: theme),
          const SizedBox(height: 24),
        ],
        _ProfileHeader(theme: theme, user: user, isOnboarding: isOnboarding),
        const SizedBox(height: 96),
        _ProfileFormCard(
          theme: theme,
          controller: controller,
          isOnboarding: isOnboarding,
        ),
        if (usageService != null) ...[
          const SizedBox(height: 24),
          _UsageInsightsCard(theme: theme, usageService: usageService),
        ],
        if (wellnessService != null) ...[
          const SizedBox(height: 24),
          _WellnessRoutinesCallout(theme: theme),
        ],
        if (moodJournalService != null) ...[
          const SizedBox(height: 24),
          _MoodJournalCallout(theme: theme),
        ],
        if (skillJourneyService != null) ...[
          const SizedBox(height: 24),
          _SkillJourneysCallout(theme: theme),
        ],
        const SizedBox(height: 24),
        _AccountDetailsCard(theme: theme, user: user),
        const SizedBox(height: 24),
        _ProfileActions(theme: theme, controller: controller),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.theme,
    required this.user,
    required this.isOnboarding,
  });

  final ThemeData theme;
  final UserModel user;
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.primaryContainer.withOpacity(0.95),
        colorScheme.primary.withOpacity(0.9),
      ],
    );

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 84),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isOnboarding ? 'Personalize sua experiência' : 'Seu perfil',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isOnboarding
                    ? 'Conte um pouco sobre você. Mesmo sem preencher tudo agora, você poderá ajustar depois.'
                    : 'Revise seus dados, personalize seu nome e gerencie sua sessão.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: -72,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(28),
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  final isCompact = cardConstraints.maxWidth < 420;
                  final double nameSize = isCompact ? 20 : 24;
                  final double emailSize = isCompact ? 13.5 : 14.5;
                  final double bioSize = isCompact ? 13.5 : 14.5;
                  final double chipSpacing = isCompact ? 6 : 8;

                  Widget details() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? user.email : user.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: nameSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: emailSize,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (user.hasBio) ...[
                          const SizedBox(height: 12),
                          Text(
                            user.bio!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: bioSize,
                              color: theme.colorScheme.onSurface.withOpacity(0.72),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: chipSpacing,
                          runSpacing: chipSpacing,
                          children: [
                            _InfoChip(icon: Icons.verified_user_outlined, label: 'Login social ativo'),
                            if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                              _InfoChip(icon: Icons.image_outlined, label: 'Avatar sincronizado'),
                            if (user.dietaryPreferences.isNotEmpty)
                              _InfoChip(
                                icon: Icons.restaurant,
                                label:
                                    '${user.dietaryPreferences.length} preferên${user.dietaryPreferences.length == 1 ? 'cia' : 'cias'} alimentares',
                              ),
                            if (user.favoriteCuisines.isNotEmpty)
                              _InfoChip(
                                icon: Icons.public,
                                label:
                                    '${user.favoriteCuisines.length} culinária${user.favoriteCuisines.length == 1 ? '' : 's'} preferida${user.favoriteCuisines.length == 1 ? '' : 's'}',
                              ),
                            if (user.cookingGoals.isNotEmpty)
                              _InfoChip(
                                icon: Icons.auto_awesome,
                                label:
                                    '${user.cookingGoals.length} objetivo${user.cookingGoals.length == 1 ? '' : 's'} na cozinha',
                              ),
                            if (user.allergies.isNotEmpty)
                              _InfoChip(
                                icon: Icons.health_and_safety,
                                label:
                                    '${user.allergies.length} alerta${user.allergies.length == 1 ? '' : 's'} de restrição',
                              ),
                          ],
                        ),
                      ],
                    );
                  }

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _Avatar(theme: theme, user: user)),
                        const SizedBox(height: 20),
                        details(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(theme: theme, user: user),
                      const SizedBox(width: 20),
                      Expanded(child: details()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileFormCard extends StatelessWidget {
  const _ProfileFormCard({
    required this.theme,
    required this.controller,
    required this.isOnboarding,
  });

  final ThemeData theme;
  final UserProfileController controller;
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Como devemos te chamar?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Este nome aparece nas telas, no card compartilhado e em sugestões personalizadas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  hintText: 'Como você quer ser chamado no app',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Informe um nome para continuar.';
                  }
                  if (text.length < 3) {
                    return 'O nome precisa ter ao menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Conte um pouco sobre você',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Use esta área para compartilhar preferências gerais, restrições ou o que mais representa seu estilo na cozinha.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio e observações',
                  hintText: 'Ex.: Curto receitas rápidas e sem lactose',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              _PreferenceSection(
                theme: theme,
                title: 'Preferências alimentares',
                description:
                    'Escolha as dietas que combinam com você. Elas ajudam o app a priorizar receitas mais relevantes.',
                suggestions: UserProfileController.dietarySuggestions,
                controller: controller,
                category: ProfilePreferenceCategory.dietary,
              ),
              const SizedBox(height: 24),
              _PreferenceSection(
                theme: theme,
                title: 'Culinárias favoritas',
                description:
                    'Marque estilos culinários que você gosta para receber recomendações alinhadas ao seu paladar.',
                suggestions: UserProfileController.cuisineSuggestions,
                controller: controller,
                category: ProfilePreferenceCategory.cuisine,
              ),
              const SizedBox(height: 24),
              _PreferenceSection(
                theme: theme,
                title: 'Objetivos na cozinha',
                description:
                    'Diga o que você busca ao cozinhar: otimizar tempo, aprender técnicas ou ter uma alimentação específica.',
                suggestions: UserProfileController.goalSuggestions,
                controller: controller,
                category: ProfilePreferenceCategory.goal,
              ),
              const SizedBox(height: 24),
              _PreferenceSection(
                theme: theme,
                title: 'Alergias e restrições',
                description:
                    'Informe ingredientes que prefere evitar. Usamos estes dados para avisar sobre receitas que possam conter riscos.',
                suggestions: UserProfileController.allergySuggestions,
                controller: controller,
                category: ProfilePreferenceCategory.allergy,
              ),
              const SizedBox(height: 24),
              Obx(
                () => FilledButton.icon(
                  onPressed: controller.isSaving.value ? null : controller.saveProfile,
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    controller.isSaving.value
                        ? 'Salvando...'
                        : (isOnboarding ? 'Salvar e continuar' : 'Salvar alterações'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingNotice extends StatelessWidget {
  const _OnboardingNotice({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: theme.colorScheme.primaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Antes de começar…',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revise seu nome e, se quiser, adicione bio e preferências. Essas informações deixam as recomendações mais relevantes, e você pode alterá-las depois.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.85),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.theme,
    required this.title,
    required this.description,
    required this.suggestions,
    required this.controller,
    required this.category,
  });

  final ThemeData theme;
  final String title;
  final String description;
  final List<String> suggestions;
  final UserProfileController controller;
  final ProfilePreferenceCategory category;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.preferencesFor(category).toList();
      final suggestionChips = suggestions.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => controller.togglePreference(category, option),
        );
      }).toList();

      final customValues = selected
          .where((item) => !suggestions.contains(item))
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (suggestionChips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: suggestionChips,
            ),
          if (customValues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Itens personalizados',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: customValues
                  .map(
                    (item) => InputChip(
                      label: Text(item),
                      onDeleted: () => controller.togglePreference(category, item),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => controller.addCustomPreference(category),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item'),
            ),
          ),
        ],
      );
    });
  }
}

class _UsageInsightsCard extends StatelessWidget {
  const _UsageInsightsCard({
    required this.theme,
    required this.usageService,
  });

  final ThemeData theme;
  final AppUsageService usageService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return StreamBuilder<AppUsageMetrics>(
      stream: usageService.metricsStream,
      initialData: usageService.metrics,
      builder: (context, snapshot) {
        final metrics = snapshot.data ?? usageService.metrics;

        final currentStreakText = _formatDayCount(metrics.currentStreak);
        final longestStreakText = _formatDayCount(metrics.longestStreak);
        final totalOpensText = _formatCount(metrics.totalOpens, 'abertura');
        final lastOpenText = _formatLastOpen(metrics.lastOpenDate);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seu ritmo no app',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe sua sequência de dias ativos e veja quando foi a última vez que explorou receitas.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final itemWidth = maxWidth >= 520 ? 240.0 : maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _UsageMetricTile(
                          theme: theme,
                          icon: Icons.local_fire_department_outlined,
                          title: currentStreakText,
                          subtitle: 'Sequência atual',
                          backgroundColor:
                              (surfaces?.surface ?? colorScheme.surfaceVariant)
                                  .withOpacity(0.6),
                          width: itemWidth,
                        ),
                        _UsageMetricTile(
                          theme: theme,
                          icon: Icons.emoji_events_outlined,
                          title: longestStreakText,
                          subtitle: 'Recorde pessoal',
                          backgroundColor:
                              colorScheme.primaryContainer.withOpacity(0.45),
                          width: itemWidth,
                        ),
                        _UsageMetricTile(
                          theme: theme,
                          icon: Icons.auto_graph_rounded,
                          title: totalOpensText,
                          subtitle: 'Aberturas totais',
                          backgroundColor:
                              colorScheme.secondaryContainer.withOpacity(0.4),
                          width: itemWidth,
                        ),
                        _UsageMetricTile(
                          theme: theme,
                          icon: Icons.schedule_outlined,
                          title: lastOpenText,
                          subtitle: 'Último acesso',
                          backgroundColor:
                              colorScheme.tertiaryContainer.withOpacity(0.45),
                          width: itemWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _UsageAchievementsSection(
                  theme: theme,
                  achievements: _buildUsageAchievements(metrics),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDayCount(int value) {
    final sanitized = value < 0 ? 0 : value;
    if (sanitized == 1) {
      return '1 dia';
    }
    return '$sanitized dias';
  }

  String _formatCount(int value, String noun) {
    final sanitized = value < 0 ? 0 : value;
    if (sanitized == 1) {
      return '1 $noun';
    }
    return '$sanitized ${noun}s';
  }

  String _formatLastOpen(DateTime? date) {
    if (date == null) {
      return 'Ainda não registrado';
    }
    final local = date.toLocal();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate =
        DateTime(local.year, local.month, local.day);
    final difference = normalizedToday.difference(normalizedDate).inDays;

    if (difference == 0) {
      return 'Hoje';
    }
    if (difference == 1) {
      return 'Ontem';
    }
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}

class _UsageMetricTile extends StatelessWidget {
  const _UsageMetricTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.width,
  });

  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.onPrimaryContainer),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageAchievementsSection extends StatelessWidget {
  const _UsageAchievementsSection({
    required this.theme,
    required this.achievements,
  });

  final ThemeData theme;
  final List<_UsageAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final unlocked = achievements.where((item) => item.unlocked).toList();
    final upcoming = achievements
        .where((item) => !item.unlocked)
        .toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));

    if (unlocked.isEmpty && upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unlocked.isNotEmpty) ...[
          Text(
            'Conquistas desbloqueadas',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: unlocked
                .map(
                  (achievement) => Chip(
                    avatar: Icon(
                      achievement.icon,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    label: Text(achievement.title),
                    backgroundColor:
                        colorScheme.primaryContainer.withOpacity(0.4),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (upcoming.isNotEmpty) ...[
          Text(
            'Próximas metas',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...upcoming.take(3).map(
                (achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AchievementProgressCard(
                    theme: theme,
                    achievement: achievement,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _AchievementProgressCard extends StatelessWidget {
  const _AchievementProgressCard({
    required this.theme,
    required this.achievement,
  });

  final ThemeData theme;
  final _UsageAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final percent = (achievement.progress * 100).clamp(0, 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surfaceVariant.withOpacity(0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(achievement.icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${achievement.current}/${achievement.target}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: achievement.progress.clamp(0, 1),
                minHeight: 6,
                backgroundColor:
                    colorScheme.surface.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percent% concluído',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageAchievement {
  const _UsageAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.progress,
    required this.current,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final double progress;
  final int current;
  final int target;
}

class _WellnessRoutinesCallout extends StatelessWidget {
  const _WellnessRoutinesCallout({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.self_improvement_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rotinas guiadas de bem-estar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Combine lembretes automáticos de hidratação, pausas ativas e preparo para o sono em pacotes prontos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.wellnessRoutines),
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Configurar rotinas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodJournalCallout extends StatelessWidget {
  const _MoodJournalCallout({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_border, color: colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Diário de bem-estar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Registre como você se sente ao cozinhar e acompanhe sua energia ao longo da semana.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () => Get.toNamed(AppRoutes.moodJournal),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Abrir diário'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillJourneysCallout extends StatelessWidget {
  const _SkillJourneysCallout({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Trilhas de habilidades',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Siga sequências guiadas para evoluir técnicas, organizar rotinas e ganhar confiança na cozinha.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.75),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.skillJourneys),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Explorar trilhas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageAchievementDefinition {
  const _UsageAchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.metricResolver,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int Function(AppUsageMetrics) metricResolver;
}

List<_UsageAchievement> _buildUsageAchievements(AppUsageMetrics metrics) {
  int _sanitize(int value) => value < 0 ? 0 : value;

  final definitions = <_UsageAchievementDefinition>[
    _UsageAchievementDefinition(
      id: 'streak_start',
      title: 'Primeiros passos',
      description: 'Complete 3 dias seguidos de uso para solidificar o hábito.',
      icon: Icons.flag_outlined,
      target: 3,
      metricResolver: (value) => value.currentStreak,
    ),
    _UsageAchievementDefinition(
      id: 'streak_week',
      title: 'Semana consistente',
      description: 'Bata o recorde de 7 dias consecutivos explorando receitas.',
      icon: Icons.calendar_month_outlined,
      target: 7,
      metricResolver: (value) => value.longestStreak,
    ),
    _UsageAchievementDefinition(
      id: 'streak_pro',
      title: 'Rotina campeã',
      description:
          'Mantenha 14 dias de sequência para mostrar que a cozinha já faz parte do seu dia a dia.',
      icon: Icons.local_fire_department_outlined,
      target: 14,
      metricResolver: (value) => value.longestStreak,
    ),
    _UsageAchievementDefinition(
      id: 'opener_explorer',
      title: 'Explorador',
      description: 'Abra o Receitagora 10 vezes para desbloquear mais sugestões.',
      icon: Icons.travel_explore_outlined,
      target: 10,
      metricResolver: (value) => value.totalOpens,
    ),
    _UsageAchievementDefinition(
      id: 'opener_master',
      title: 'Maratona gourmet',
      description: 'Chegue a 30 aberturas acumuladas e mantenha o ritmo criativo.',
      icon: Icons.bolt_outlined,
      target: 30,
      metricResolver: (value) => value.totalOpens,
    ),
    _UsageAchievementDefinition(
      id: 'fresh_today',
      title: 'Dia em dia',
      description: 'Volte hoje mesmo para não deixar sua sequência esfriar.',
      icon: Icons.refresh_outlined,
      target: 1,
      metricResolver: (value) {
        final lastOpen = value.lastOpenDate;
        if (lastOpen == null) {
          return 0;
        }
        final local = lastOpen.toLocal();
        final today = DateTime.now();
        if (local.year == today.year &&
            local.month == today.month &&
            local.day == today.day) {
          return 1;
        }
        return 0;
      },
    ),
  ];

  return definitions.map((definition) {
    final currentValue = _sanitize(definition.metricResolver(metrics));
    final progress = currentValue / definition.target;
    return _UsageAchievement(
      id: definition.id,
      title: definition.title,
      description: definition.description,
      icon: definition.icon,
      unlocked: currentValue >= definition.target,
      progress: progress.isFinite ? progress : 0,
      current: currentValue,
      target: definition.target,
    );
  }).toList();
}

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({
    required this.theme,
    required this.user,
  });

  final ThemeData theme;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'E-mail',
              value: user.email,
            ),
            const Divider(height: 1),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Identificador único',
              value: user.id,
              denseValue: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.theme,
    required this.controller,
  });

  final ThemeData theme;
  final UserProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gerenciar sessão',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
        Text(
          'Caso queira usar outra conta, você pode encerrar esta sessão a qualquer momento.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final isPremium = controller.isPremiumUser.value;
          final plan = controller.subscriptionPlan.value;
          final busy = controller.isBillingBusy.value;

          String subtitle;
          if (isPremium) {
            final expires = plan?.expiresAt;
            if (plan?.autoRenews == true && expires != null) {
              subtitle = 'Renova em ${_formatDate(expires)}';
            } else if (plan?.autoRenews == true) {
              subtitle = 'Renovação automática ativa';
            } else if (expires != null) {
              subtitle = 'Expira em ${_formatDate(expires)}';
            } else {
              subtitle = 'Assinatura Premium ativa';
            }
          } else {
            subtitle =
                'Libere cardápios nutricionais e o laboratório de ingredientes com o Premium.';
          }

          final trailing = busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !busy,
                leading: Icon(
                  isPremium
                      ? Icons.workspace_premium_outlined
                      : Icons.lock_open_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Receita Agora Premium',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                trailing: trailing,
                onTap: busy
                    ? null
                    : (isPremium
                        ? controller.viewSubscriptionDetails
                        : controller.openPremiumPlans),
              ),
              if (isPremium) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed:
                        busy ? null : controller.requestSubscriptionCancellation,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Solicitar cancelamento'),
                  ),
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Obx(
          () => OutlinedButton.icon(
            onPressed: controller.isSigningOut.value ? null : controller.signOut,
                icon: controller.isSigningOut.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(controller.isSigningOut.value ? 'Saindo...' : 'Sair do aplicativo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.theme,
    required this.user,
  });

  final ThemeData theme;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 42,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
          ? Text(
              _initialsFrom(user.name, user.email),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            )
          : null,
    );
  }

  String _initialsFrom(String name, String email) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, trimmed.length > 2 ? 2 : trimmed.length).toUpperCase();
    }
    final fallback = email.trim();
    if (fallback.isNotEmpty) {
      return fallback.substring(0, fallback.length > 2 ? 2 : fallback.length).toUpperCase();
    }
    return '?';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.12)),
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.denseValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool denseValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: SelectableText(
        value,
        style: denseValue
            ? theme.textTheme.bodySmall
            : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
