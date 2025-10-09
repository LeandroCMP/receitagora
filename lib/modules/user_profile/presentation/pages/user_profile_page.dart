import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/utils/app_layout.dart';
import '../controllers/user_profile_controller.dart';

class UserProfilePage extends GetView<UserProfileController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<AppSurfaceColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.theme,
    required this.controller,
  });

  final ThemeData theme;
  final UserProfileController controller;

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

    final emailStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    final avatar = CircleAvatar(
      radius: 36,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
      child: user.avatarUrl == null
          ? Text(
              _initialsFrom(user.displayName, user.email),
              style: theme.textTheme.titleMedium,
            )
          : null,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  avatar,
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: emailStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${user.id}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
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
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isSaving.value ? null : controller.saveDisplayName,
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(controller.isSaving.value ? 'Salvando...' : 'Salvar alterações'),
                ),
              ),
              const SizedBox(height: 12),
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
      ),
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
