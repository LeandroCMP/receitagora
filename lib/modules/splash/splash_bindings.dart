import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:receitagora/services/session/session_service.dart';

import 'splash_controller.dart';

class SplashBindings extends Bindings {
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
