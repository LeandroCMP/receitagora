import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
class SplashController extends GetxController {

  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));

    Get.offAllNamed(AppRoutes.login);
  }
}
