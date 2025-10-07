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
    await sessionService.ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 1600));

    if (sessionService.hasActiveSession) {
      Get.offAllNamed(AppRoutes.recipeFinder);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
