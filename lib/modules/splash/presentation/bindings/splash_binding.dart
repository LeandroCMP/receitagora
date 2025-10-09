import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(
        sessionService: Get.find<SessionService>(),
        firebaseAuth: Get.find<FirebaseAuth>(),
      ),
    );
  }
}
