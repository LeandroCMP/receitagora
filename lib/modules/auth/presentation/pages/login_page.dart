import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/ui/responsive.dart';
import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(theme.colorScheme.primary.withOpacity(0.08), background),
                  background,
                  Color.alphaBlend(Colors.black.withOpacity(0.18), background),
                ],
              ),
            ),
          ),
          Positioned(
            top: -160,
            right: -120,
            child: _BlurOrb(color: theme.colorScheme.primary.withOpacity(0.25)),
          ),
          Positioned(
            bottom: -220,
            left: -120,
            child: _BlurOrb(color: theme.colorScheme.secondary.withOpacity(0.16)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final horizontalPadding =
                    AppResponsive.valueForWidth(
                  width: width,
                  compact: 20,
                  medium: 32,
                  expanded: 48,
                );
                final maxWidth = AppResponsive.valueForWidth<double>(
                  width: width,
                  compact: width,
                  medium: 520,
                  expanded: 560,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, headerConstraints) {
                              final headerWidth = headerConstraints.maxWidth;
                              final isCompactHeader = AppResponsive.isCompact(headerWidth);
                              final avatar = CircleAvatar(
                                radius: 28,
                                backgroundColor: theme.colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  size: 30,
                                ),
                              );

                              final headline = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olá, convidado'.toUpperCase(),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      letterSpacing: 1.4,
                                      color: theme.colorScheme.onBackground.withOpacity(0.68),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pronto para cozinhar?\nDescubra combinações perfeitas.',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              );

                              if (isCompactHeader) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    avatar,
                                    const SizedBox(height: 18),
                                    headline,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: headline),
                                  const SizedBox(width: 18),
                                  avatar,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          const _HeroCard(),
                          const SizedBox(height: 32),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(28, 32, 28, 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Entre como visitante',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Descubra receitas em segundos. Você pode fazer até três buscas por dia no modo visitante.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 28),
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
                                            const Text('Começar agora'),
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
                                  const SizedBox(height: 26),
                                  _GuestQuotaHint(theme: theme),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Receitas elegantes, filtros inteligentes e um visual inspirado em apps premium de culinária.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.62),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardHeight = AppResponsive.valueForWidth<double>(
          width: width,
          compact: 280,
          medium: 260,
          expanded: 240,
        );
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.86),
            theme.colorScheme.primary.withOpacity(0.35),
            theme.colorScheme.primary.withOpacity(0.12),
          ],
        );

        final metaItems = [
          const _HeroMeta(icon: Icons.schedule_rounded, label: '40 min'),
          const _HeroMeta(icon: Icons.whatshot_outlined, label: 'Fácil'),
          const _HeroMeta(icon: Icons.star_rounded, label: '4.8'),
        ];

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: gradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: 36,
                    child: Container(
                      width: AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 160,
                        medium: 180,
                        expanded: 190,
                      ),
                      height: AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 160,
                        medium: 180,
                        expanded: 190,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppResponsive.valueForWidth<double>(
                      width: width,
                      compact: 22,
                      medium: 24,
                      expanded: 26,
                    ),
                    top: 30,
                    child: Container(
                      width: AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 120,
                        medium: 130,
                        expanded: 140,
                      ),
                      height: AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 120,
                        medium: 130,
                        expanded: 140,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      child: Icon(
                        Icons.ramen_dining,
                        color: Colors.black.withOpacity(0.78),
                        size: AppResponsive.valueForWidth<double>(
                          width: width,
                          compact: 48,
                          medium: 52,
                          expanded: 54,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 22,
                        medium: 26,
                        expanded: 28,
                      ),
                      AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 26,
                        medium: 28,
                        expanded: 32,
                      ),
                      AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 22,
                        medium: 26,
                        expanded: 28,
                      ),
                      AppResponsive.valueForWidth<double>(
                        width: width,
                        compact: 26,
                        medium: 28,
                        expanded: 28,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            'Sugestão do dia',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Chicken baked com ervas',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Uma inspiração para você começar — e nós cuidamos do resto na próxima busca.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            height: 1.45,
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: metaItems,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _GuestQuotaHint extends StatelessWidget {
  const _GuestQuotaHint({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Até 3 buscas por dia com duas receitas por vez. Entre com o Google futuramente para salvar favoritos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.72),
                    height: 1.45,
                  ),
                ),
              ],
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
