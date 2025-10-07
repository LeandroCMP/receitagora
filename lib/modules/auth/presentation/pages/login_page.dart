import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final highlight = theme.colorScheme.primary.withOpacity(0.12);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.alphaBlend(theme.colorScheme.primary.withOpacity(0.12), background),
                  background,
                  Color.alphaBlend(theme.colorScheme.secondary.withOpacity(0.08), background),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: _BlurOrb(color: theme.colorScheme.primary.withOpacity(0.32)),
          ),
          Positioned(
            bottom: -140,
            right: -60,
            child: _BlurOrb(color: theme.colorScheme.secondary.withOpacity(0.28)),
          ),
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 520 ? 460.0 : constraints.maxWidth;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BrandHeader(theme: theme),
                          const SizedBox(height: 36),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Comece agora',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Explore ideias com um toque de chef no modo visitante enquanto o login social não chega.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.68),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 30),
                                  Obx(
                                    () => FilledButton(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : controller.continueAsGuest,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (controller.isLoading.value)
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.onPrimary,
                                                  ),
                                                ),
                                              )
                                            else
                                              const Icon(Icons.bolt_rounded),
                                            const SizedBox(width: 12),
                                            const Text('Entrar como visitante'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Obx(
                                    () => OutlinedButton.icon(
                                      icon: _GoogleBadge(theme: theme),
                                      label: const Text('Google (em breve)'),
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : controller.signInWithGoogle,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: highlight,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: _GuestQuotaHint(theme: theme),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Receitas sob medida com uma experiência acolhedora e moderna para inspirar o seu cardápio.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.65),
                              height: 1.5,
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
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(0.95),
        theme.colorScheme.secondary.withOpacity(0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.35),
                blurRadius: 42,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: const Icon(Icons.restaurant_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 28),
        Text(
          'Receita Agora',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Descubra combinações perfeitas em poucos toques.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.64),
            height: 1.45,
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
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          child: Icon(Icons.hourglass_bottom_rounded, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo visitante',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Até 3 buscas por dia e 2 receitas por consulta. O login Google destravará favoritos em breve.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFABB05),
            Color(0xFFEA4335),
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

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.05)],
        ),
      ),
    );
  }
}
