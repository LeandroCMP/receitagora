import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/utils/app_layout.dart';
import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.background;
    final surfaces = theme.extension<AppSurfaceColors>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                theme.colorScheme.primary.withOpacity(0.08),
                surfaces?.lowest ?? background,
              ),
              background,
              Color.alphaBlend(
                theme.colorScheme.secondary.withOpacity(0.06),
                surfaces?.low ?? background,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppPageLayout.resolve(
                constraints,
                maxWidth: 640,
                topPadding: 44,
                bottomPadding: 44,
              );

              return SingleChildScrollView(
                padding: layout.padding,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginHeader(theme: theme),
                        const SizedBox(height: 36),
                        _GuestCard(controller: controller),
                        const SizedBox(height: 24),
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
                theme.colorScheme.primaryContainer.withOpacity(0.85),
                theme.colorScheme.primary.withOpacity(0.35),
              ],
            ),
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: theme.colorScheme.onPrimaryContainer,
            size: 32,
          ),
        );

        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receitagora',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Encontre combinações deliciosas com os ingredientes que você já tem em casa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
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

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrar como visitante',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Acesse rapidamente o Receitagora com até três buscas por dia e visualize duas sugestões por pesquisa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.45,
              ),
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
    final surfaces = theme.extension<AppSurfaceColors>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrar com Google',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estamos preparando o login social para liberar mais buscas e salvar suas receitas preferidas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    shape: const CircleBorder(),
                    color: surfaces?.surface.withOpacity(0.8) ??
                        theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    child: InkWell(
                      onTap: controller.signInWithGoogle,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: _GoogleMark(size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Em breve',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleMarkPainter(),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Blue arc and horizontal stroke
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(strokeWidth * 0.45), -40 * (math.pi / 180),
        230 * (math.pi / 180), false, paint);
    canvas.drawLine(Offset(size.width * 0.48, size.height * 0.52),
        Offset(size.width * 0.88, size.height * 0.52), paint);

    // Red segment
    paint.color = const Color(0xFFEA4335);
    canvas.drawLine(Offset(size.width * 0.82, size.height * 0.52),
        Offset(size.width * 0.82, size.height * 0.78), paint);

    // Yellow segment
    paint.color = const Color(0xFFFABB05);
    canvas.drawArc(rect.deflate(strokeWidth * 0.45), 200 * (math.pi / 180),
        110 * (math.pi / 180), false, paint);

    // Green segment
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(strokeWidth * 0.45), 110 * (math.pi / 180),
        90 * (math.pi / 180), false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
