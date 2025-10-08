import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(theme.colorScheme.primary.withOpacity(0.08), background),
              background,
              Color.alphaBlend(theme.colorScheme.secondary.withOpacity(0.06), background),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontalPadding = width < 420
                  ? 20.0
                  : width < 720
                      ? 32.0
                      : 48.0;
              final maxWidth = width < 720 ? width : 640.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    32,
                    horizontalPadding,
                    40,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LoginHeader(theme: theme),
                        const SizedBox(height: 28),
                        const _HighlightCard(),
                        const SizedBox(height: 28),
                        _GuestCard(controller: controller),
                        const SizedBox(height: 20),
                        _ComingSoonCard(controller: controller),
                      ],
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 520;

        final avatar = Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.primary.withOpacity(0.4),
              ],
            ),
          ),
          child: Icon(Icons.restaurant_menu, color: theme.colorScheme.onPrimary, size: 32),
        );

        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receita Agora',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Descubra receitas que combinam com os ingredientes que você tem à mão.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.68),
                height: 1.45,
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(height: 20),
              text,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: text),
            const SizedBox(width: 24),
            avatar,
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.3),
              theme.colorScheme.primary.withOpacity(0.08),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Experiência personalizada'.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Conte o que tem na sua cozinha e o ChatGPT cria sugestões sob medida. Cada receita vem com tempo de preparo, dificuldade e modo de fazer.',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Entrar como visitante',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Você pode realizar até três buscas por dia e cada pesquisa retorna duas sugestões exclusivas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Obx(
              () => FilledButton(
                onPressed: controller.isLoading.value ? null : controller.continueAsGuest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isLoading.value) ...[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ]
                      else ...[
                        const Icon(Icons.rocket_launch_rounded),
                        const SizedBox(width: 12),
                      ],
                      const Text('Começar agora'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preferir entrar com Google?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estamos finalizando uma experiência de login social para liberar buscas ilimitadas e sincronizar suas receitas favoritas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: controller.signInWithGoogle,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Entrar com Google (em breve)'),
            ),
          ],
        ),
      ),
    );
  }
}
