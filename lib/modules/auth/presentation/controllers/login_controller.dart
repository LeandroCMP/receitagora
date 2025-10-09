import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';

class LoginController extends GetxController {
  LoginController({
    required this.sessionService,
    required this.authService,
  });

  final SessionService sessionService;
  final AuthService authService;

  final isGuestLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isGoogleSignOutLoading = false.obs;

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value) {
      return;
    }

    isGoogleLoading.value = true;

    try {
      await sessionService.ensureInitialized();
      await authService.signInWithGoogle();
      await Get.offAllNamed(AppRoutes.recipeFinder);
    } on AuthFailure catch (error) {
      if (!error.isCancelled) {
        final message = error.message.isEmpty
            ? 'Não foi possível completar o login com Google. Tente novamente.'
            : error.message;
        _showErrorSnackbar(
          titulo: 'Não foi possível entrar',
          mensagem: message,
        );
      }
    } catch (_) {
      _showErrorSnackbar(
        titulo: 'Erro inesperado',
        mensagem: 'Não conseguimos concluir o login com Google. Tente novamente em instantes.',
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  Future<void> continueAsGuest() async {
    if (isGuestLoading.value) {
      return;
    }

    isGuestLoading.value = true;

    try {
      await sessionService.ensureInitialized();
      await sessionService.continueAsGuest();
      await Get.offAllNamed(AppRoutes.recipeFinder);
    } finally {
      isGuestLoading.value = false;
    }
  }

  Future<void> signOutFromGoogle() async {
    if (isGoogleSignOutLoading.value) {
      return;
    }

    isGoogleSignOutLoading.value = true;

    try {
      await authService.signOut();
      _showInfoSnackbar(
        titulo: 'Sessão encerrada',
        mensagem: 'O login social foi desconectado para um novo teste.',
      );
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não foi possível desconectar o login com Google. Tente novamente.'
          : error.message;
      _showErrorSnackbar(
        titulo: 'Falha ao sair',
        mensagem: message,
      );
    } catch (_) {
      _showErrorSnackbar(
        titulo: 'Erro inesperado',
        mensagem: 'Não conseguimos finalizar o logout. Tente novamente em instantes.',
      );
    } finally {
      isGoogleSignOutLoading.value = false;
    }
  }

  void _showErrorSnackbar({required String titulo, required String mensagem}) {
    Get.snackbar(
      titulo,
      mensagem,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.errorContainer.withOpacity(0.95),
      colorText: Get.theme.colorScheme.onErrorContainer,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
    );
  }

  void _showInfoSnackbar({required String titulo, required String mensagem}) {
    final theme = Get.theme;
    Get.snackbar(
      titulo,
      mensagem,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.92),
      colorText: theme.colorScheme.onPrimaryContainer,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
    );
  }
}
