import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/application/utils/app_snackbar.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/session/session_service.dart';

class UserProfileController extends GetxController {
  UserProfileController({
    required this.sessionService,
    required this.authService,
  });

  final SessionService sessionService;
  final AuthService authService;

  late final TextEditingController nameController;
  final formKey = GlobalKey<FormState>();

  final isSaving = false.obs;
  final isSigningOut = false.obs;

  UserModel? get user => sessionService.user;

  @override
  void onInit() {
    super.onInit();
    final initialName = sessionService.user?.name ?? '';
    nameController = TextEditingController(text: initialName);
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> saveDisplayName() async {
    if (isSaving.value) {
      return;
    }

    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      return;
    }

    isSaving.value = true;

    try {
      await authService.updateDisplayName(newName);
      AppSnackbar.success(
        title: 'Perfil atualizado',
        message: 'Seu nome foi atualizado com sucesso.',
      );
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não foi possível atualizar seu nome agora. Tente novamente.'
          : error.message;
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Ocorreu um erro inesperado ao atualizar seu nome. Tente novamente.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> signOut() async {
    if (isSigningOut.value) {
      return;
    }

    isSigningOut.value = true;

    try {
      await authService.signOut();
      await Get.offAllNamed(AppRoutes.login);
    } on AuthFailure catch (error) {
      final message = error.message.isEmpty
          ? 'Não foi possível encerrar a sessão agora. Tente novamente.'
          : error.message;
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: message,
      );
    } catch (_) {
      AppSnackbar.error(
        title: 'Algo deu errado',
        message: 'Não conseguimos encerrar sua sessão. Tente novamente em instantes.',
      );
    } finally {
      isSigningOut.value = false;
    }
  }
}
