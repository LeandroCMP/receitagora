import 'package:get/get.dart';

import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'login_controller.dart';

class LoginBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(
        sessionService: Get.find<SessionService>(),
        authService: Get.find<AuthService>(),
      ),
    );
  }
}
