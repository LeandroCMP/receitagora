import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centraliza o controle do loading bloqueante exibido durante operações
/// críticas, reutilizando o mesmo indicador circular utilizado em outras
/// partes do app (como o compartilhamento de receitas).
class AppLoading {
  AppLoading._();

  static bool _isShowing = false;
  static BuildContext? _dialogContext;

  /// Exibe o overlay bloqueante se ainda não houver nenhum diálogo aberto.
  static void show() {
    if (_isShowing) {
      return;
    }

    final context = Get.overlayContext ?? Get.context;
    if (context == null) {
      return;
    }

    _isShowing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return const Center(child: CircularProgressIndicator());
      },
    ).whenComplete(() {
      _dialogContext = null;
      _isShowing = false;
    });
  }

  /// Fecha o overlay bloqueante caso esteja visível.
  static void hide() {
    if (!_isShowing) {
      return;
    }

    var didClose = false;

    if (_dialogContext != null) {
      Navigator.of(_dialogContext!, rootNavigator: true).pop();
      didClose = true;
    } else if (Get.isDialogOpen ?? false) {
      Get.back<void>();
      didClose = true;
    } else {
      final overlay = Get.overlayContext;
      if (overlay != null && Navigator.of(overlay, rootNavigator: true).canPop()) {
        Navigator.of(overlay, rootNavigator: true).pop();
        didClose = true;
      }
    }

    if (!didClose) {
      final navigator = Get.key.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    }

    _dialogContext = null;
    _isShowing = false;
  }

  /// Executa [operation] exibindo o overlay automaticamente enquanto a
  /// operação estiver em andamento.
  static Future<T> guard<T>(Future<T> Function() operation) async {
    show();
    try {
      return await operation();
    } finally {
      hide();
    }
  }
}
