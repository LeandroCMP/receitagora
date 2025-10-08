import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                surfaces?.lowest ?? theme.colorScheme.background,
              ),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.85),
                      theme.colorScheme.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Receitagora',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sabores feitos para o seu momento.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.68),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.2),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
