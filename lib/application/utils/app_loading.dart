import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoading {
  AppLoading._();

  static bool _isShowing = false;

  static Future<void> showBlocking({String? message}) async {
    if (_isShowing) {
      return;
    }
    _isShowing = true;

    await Future<void>.delayed(Duration.zero);

    if (Get.isDialogOpen ?? false) {
      _isShowing = false;
      return;
    }

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null && message.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (_isShowing && (Get.isDialogOpen ?? false)) {
      Get.back();
    }
    _isShowing = false;
  }
}
