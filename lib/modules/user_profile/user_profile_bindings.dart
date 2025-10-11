import 'package:get/get.dart';

import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'user_profile_controller.dart';

class UserProfileBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserProfileController>(
      () => UserProfileController(
        sessionService: Get.find<SessionService>(),
        authService: Get.find<AuthService>(),
      ),
    );
  }
}
