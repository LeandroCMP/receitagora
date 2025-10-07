import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/session_service.dart';

class LoginController extends GetxController {
  LoginController({required this.sessionService});

  final SessionService sessionService;

  final isLoading = false.obs;

  void signInWithGoogle() {
    Get.snackbar(
      'Em breve',
      'O login com Google estará disponível nas próximas versões.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.surfaceVariant.withOpacity(0.9),
      colorText: Get.theme.colorScheme.onSurfaceVariant,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }

  Future<void> continueAsGuest() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;

    try {
      await sessionService.ensureInitialized();
      await sessionService.continueAsGuest();
      await Get.offAllNamed(AppRoutes.recipeFinder);
    } finally {
      isLoading.value = false;
    }
  }
}
