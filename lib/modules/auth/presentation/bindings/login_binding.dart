import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
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
