import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';
import '../controllers/user_profile_controller.dart';

class UserProfileBinding extends Bindings {
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
