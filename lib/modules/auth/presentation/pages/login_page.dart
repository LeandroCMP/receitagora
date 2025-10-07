import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final primaryVeil = Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.08),
      background,
    );
    final secondaryVeil = Color.alphaBlend(
      theme.colorScheme.secondary.withOpacity(0.06),
      background,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryVeil, background, secondaryVeil],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 520 ? 480 : constraints.maxWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BrandHeader(theme: theme),
                        const SizedBox(height: 32),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Como você prefere continuar?',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Obx(
                                  () => FilledButton.icon(
                                    icon: controller.isLoading.value
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.person_outline),
                                    label: const Text('Entrar como visitante'),
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.continueAsGuest,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Obx(
                                  () => OutlinedButton.icon(
                                    icon: _GoogleBadge(theme: theme),
                                    label: const Text('Continuar com o Google'),
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.signInWithGoogle,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Login social disponível em breve. Use o modo visitante para experimentar agora mesmo.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),
                                _GuestQuotaHint(theme: theme),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Receitas inteligentes com uma experiência acolhedora e intuitiva para o seu dia a dia.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.72),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.85),
                theme.colorScheme.secondary.withOpacity(0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.restaurant, size: 34, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'Receita Agora',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Descubra combinações deliciosas com poucos toques.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GuestQuotaHint extends StatelessWidget {
  const _GuestQuotaHint({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withOpacity(0.06),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo visitante: até 3 buscas por dia com 2 receitas por pesquisa.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          'G',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
