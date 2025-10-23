import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/widgets/app_page_background.dart';

import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppPageBackground(
        showSecondaryHighlight: false,
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.95 + (value * 0.05),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 104,
                  width: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.22),
                        blurRadius: 34,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: theme.colorScheme.onPrimary,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Receita Agora',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sabores afetivos, criatividade e praticidade em cada sugestão.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withValues(alpha: 0.68),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
