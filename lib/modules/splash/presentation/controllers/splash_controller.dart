import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/session_service.dart';

class SplashController extends GetxController {
  SplashController({required this.sessionService});

  final SessionService sessionService;

  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      await sessionService.ensureInitialized().timeout(
            const Duration(seconds: 5),
          );
    } catch (error, stackTrace) {
      Get.log(
        'Failed to hydrate session before leaving splash: $error\n$stackTrace',
        isError: true,
      );
    }

    await Future.delayed(const Duration(seconds: 3));

    Get.offAllNamed(AppRoutes.login);
  }
}
