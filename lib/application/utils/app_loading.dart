import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoading {
  AppLoading._();

  static bool _isShowing = false;

  static Future<void> showBlocking() async {
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
        child: const Center(
          child: CircularProgressIndicator(),
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
