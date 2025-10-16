import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';
import 'package:receitagora/application/ui/widgets/app_page_background.dart';
import 'package:receitagora/application/utils/app_layout.dart';

import 'login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 680,
                topPadding: 36,
                bottomPadding: 48,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: 32),
                          _LoginOptions(controller: controller),
                          const SizedBox(height: 32),
                          _PrivacyNote(theme: theme),
                        ],
                      ),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 24),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                (surfaces?.surface ?? theme.colorScheme.surface),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              final double titleSize = isCompact ? 28 : 32;
              final double bodySize = isCompact ? 15 : 16;

              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receita Agora',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Transforme ingredientes em pratos memoráveis em poucos toques. '
                    'Descubra combinações pensadas para o seu momento e organize suas favoritas.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: bodySize,
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.78),
                      height: 1.55,
                    ),
                  ),
                ],
              );

              final illustration = SizedBox(
                height: isCompact ? 160 : 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: isCompact ? 36 : 24,
                      child: Container(
                        height: isCompact ? 120 : 140,
                        width: isCompact ? 120 : 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.45),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.24),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bakery_dining_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: isCompact ? 52 : 60,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 26,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sugestões personalizadas',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 28),
                    illustration,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 32),
                  illustration,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginOptions extends StatelessWidget {
  const _LoginOptions({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 32, 30, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_people_rounded,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Explorar como visitante',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Experimente duas buscas por dia com sugestões curadas e veja como a experiência funciona antes de criar sua conta.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => FilledButton(
                      onPressed: controller.isGuestLoading.value
                          ? null
                          : controller.continueAsGuest,
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: controller.isGuestLoading.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Usar modo visitante',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 32, 30, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Entre com sua conta',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sincronize favoritos, histórico e preferências em todos os dispositivos. Você poderá ajustar seu perfil logo após o login.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: controller.isGoogleLoading.value
                          ? null
                          : controller.signInWithGoogle,
                      icon: controller.isGoogleLoading.value
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.login_rounded,
                              color: theme.colorScheme.onPrimary,
                            ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          controller.isGoogleLoading.value
                              ? 'Conectando...'
                              : 'Continuar com o Google',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: controller.googleErrorMessage.value == null
                          ? const SizedBox.shrink()
                          : Text(
                              controller.googleErrorMessage.value!,
                              key: ValueKey(controller.googleErrorMessage.value),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ao continuar, você concorda em compartilhar seu nome e e-mail apenas para manter seu perfil e seus favoritos sincronizados. Podemos enviar atualizações sobre novidades e dicas sazonais.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}
