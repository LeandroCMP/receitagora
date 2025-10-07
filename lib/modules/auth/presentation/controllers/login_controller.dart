import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/session_service.dart';

class LoginController extends GetxController {
  LoginController({required this.sessionService});

  final SessionService sessionService;

  final isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;

    try {
      await sessionService.signInWithGoogle();
      Get.offAllNamed(AppRoutes.recipeFinder);
    } catch (error) {
      final message = _mapErrorToMessage(error);
      Get.snackbar(
        'Não foi possível entrar',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.surfaceVariant.withOpacity(0.9),
        colorText: Get.theme.colorScheme.onSurfaceVariant,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueAsGuest() async {
    if (isLoading.value) {
      return;
    }

    await sessionService.continueAsGuest();
    Get.offAllNamed(AppRoutes.recipeFinder);
  }

  String _mapErrorToMessage(Object error) {
    final description = error.toString();

    if (description.toLowerCase().contains('network')) {
      return 'Verifique sua conexão e tente novamente.';
    }

    if (description.toLowerCase().contains('cancel')) {
      return 'O login foi cancelado. Tente novamente quando quiser.';
    }

    return 'Não foi possível conectar ao Google agora. Tente novamente em instantes.';
  }
}
