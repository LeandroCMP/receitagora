import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/ui/theme_extensions.dart';

enum AppSnackbarStyle { info, success, warning, error }

/// Helper responsible for displaying snackbars with consistent styling across
/// the application. Centralising the feedback logic avoids duplicated color
/// calculations in every controller and keeps the overall behaviour aligned
/// with the rest of the codebase inspired by the Air Sync project structure.
class AppSnackbar {
  const AppSnackbar._();

  static void info({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      title: title,
      message: message,
      style: AppSnackbarStyle.info,
      duration: duration,
    );
  }

  static void success({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      title: title,
      message: message,
      style: AppSnackbarStyle.success,
      duration: duration,
    );
  }

  static void warning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      title: title,
      message: message,
      style: AppSnackbarStyle.warning,
      duration: duration,
    );
  }

  static void error({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      title: title,
      message: message,
      style: AppSnackbarStyle.error,
      duration: duration,
    );
  }

  static void show({
    required String title,
    required String message,
    AppSnackbarStyle style = AppSnackbarStyle.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Get.theme;
    final colorScheme = theme.colorScheme;
    final surfaces = theme.extension<ReceitagoraSurfaceColors>();

    late final Color background;
    late final Color foreground;

    switch (style) {
      case AppSnackbarStyle.success:
        background = colorScheme.primaryContainer.withOpacity(0.92);
        foreground = colorScheme.onPrimaryContainer;
        break;
      case AppSnackbarStyle.warning:
        background = colorScheme.tertiaryContainer.withOpacity(0.94);
        foreground = colorScheme.onTertiaryContainer;
        break;
      case AppSnackbarStyle.error:
        background = colorScheme.errorContainer.withOpacity(0.95);
        foreground = colorScheme.onErrorContainer;
        break;
      case AppSnackbarStyle.info:
      default:
        background = (surfaces?.high ?? colorScheme.surfaceVariant).withOpacity(0.92);
        foreground = colorScheme.onSurface;
        break;
    }

    if (Get.isSnackbarOpen ?? false) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      backgroundColor: background,
      colorText: foreground,
      duration: duration,
    );
  }
}
