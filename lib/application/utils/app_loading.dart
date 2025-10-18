import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centraliza o controle do loading bloqueante exibido durante operações
/// críticas, reutilizando o mesmo indicador circular utilizado em outras
/// partes do app (como o compartilhamento de receitas).
class AppLoading {
  AppLoading._();

  static bool _isShowing = false;

  /// Exibe o overlay bloqueante se ainda não houver nenhum diálogo aberto.
  static void show() {
    if (_isShowing || (Get.isDialogOpen ?? false)) {
      return;
    }
    _isShowing = true;
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    ).whenComplete(() {
      _isShowing = false;
    });
  }

  /// Fecha o overlay bloqueante caso esteja visível.
  static void hide() {
    if (_isShowing && (Get.isDialogOpen ?? false)) {
      Get.back<void>();
    }
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
