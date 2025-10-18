import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/session/session_service.dart';

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
  final googleErrorMessage = RxnString();

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value) {
      return;
    }

    isGoogleLoading.value = true;
    googleErrorMessage.value = null;

    try {
      await sessionService.ensureInitialized();
      final user = await authService.signInWithGoogle();

      await sessionService.ensureTesterPremiumAccessIfNeeded();
      // Temporarily inform the user about their subscription status right
      // after login so testers can verify premium recognition flows.
      await sessionService.refreshSubscriptionPlan();
      final plan = sessionService.plan;
      if (sessionService.hasPremiumAccess || plan?.isPremium == true) {
        AppSnackbar.success(
          title: 'Assinatura ativa',
          message: 'Sua conta está no plano Premium. Aproveite os benefícios!',
        );
      } else {
        AppSnackbar.info(
          title: 'Plano gratuito',
          message: 'Sua conta está no plano gratuito no momento.',
        );
      }

      googleErrorMessage.value = null;
      if (user.profileCompleted) {
        await Get.offAllNamed(AppRoutes.recipeFinder);
      } else {
        await Get.offAllNamed(
          AppRoutes.userProfile,
          arguments: const <String, dynamic>{'onboarding': true},
        );
      }
    } on AuthFailure catch (error) {
      if (!error.isCancelled) {
        final message = error.message.isEmpty
            ? 'Não foi possível completar o login com Google. Tente novamente.'
            : error.message;
        googleErrorMessage.value = message;
        AppSnackbar.error(
          title: 'Não foi possível entrar',
          message: message,
        );
      }
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message: 'Não conseguimos concluir o login com Google. Tente novamente em instantes.',
      );
      googleErrorMessage.value =
          'Não conseguimos concluir o login com Google. Tente novamente em instantes.';
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
      AppSnackbar.info(
        title: 'Sessão encerrada',
        message: 'O login social foi desconectado para um novo teste.',
      );
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não foi possível desconectar o login com Google. Tente novamente.'
          : error.message;
      AppSnackbar.error(
        title: 'Falha ao sair',
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Erro inesperado',
        message: 'Não conseguimos finalizar o logout. Tente novamente em instantes.',
      );
    } finally {
      isGoogleSignOutLoading.value = false;
    }
  }
}
