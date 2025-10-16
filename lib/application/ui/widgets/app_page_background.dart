import 'package:flutter/material.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';

/// Shared background used across the app pages to keep the new light theme
/// consistent with subtle gradients and organic highlights inspired by
/// culinary photography lighting setups.
class AppPageBackground extends StatelessWidget {
  const AppPageBackground({
    required this.child,
    this.highlightAlignment = const Alignment(0.85, -0.85),
    this.showSecondaryHighlight = true,
    super.key,
  });

  final Widget child;
  final Alignment highlightAlignment;
  final bool showSecondaryHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: highlightAlignment,
          radius: 1.05,
          colors: [
            theme.colorScheme.primary.withOpacity(0.22),
            surfaces?.lowest ?? theme.colorScheme.background,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (surfaces?.highest ?? theme.colorScheme.background)
                  .withOpacity(0.96),
              surfaces?.surface ?? theme.colorScheme.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            if (showSecondaryHighlight)
              Align(
                alignment: const Alignment(-1.1, 0.9),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, 0),
                      radius: 0.9,
                      colors: [
                        theme.colorScheme.secondary.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
