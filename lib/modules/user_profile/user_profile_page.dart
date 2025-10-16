import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/utils/app_layout.dart';
import 'package:receitagora/models/user_model.dart';

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

                  return SingleChildScrollView(
                    padding: layout.padding,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                        child: _ProfileContent(
                          theme: theme,
                          controller: controller,
                          isOnboarding: onboarding,
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
        const SizedBox(height: 16),
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
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnboarding ? 'Personalize sua experiência' : 'Seu perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOnboarding
                      ? 'Conte um pouco sobre você. Mesmo sem preencher tudo agora, você poderá ajustar depois.'
                      : 'Revise seus dados, personalize seu nome e gerencie sua sessão.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.85),
                  ),
                ),
              ],
            ),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(theme: theme, user: user),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? user.email : user.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (user.hasBio) ...[
                          const SizedBox(height: 12),
                          Text(
                            user.bio!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.72),
                              height: 1.45,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                    ),
                  ),
                ],
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
