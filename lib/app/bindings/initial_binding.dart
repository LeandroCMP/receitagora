import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/config/environment_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/openai_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<EnvironmentConfig>(EnvironmentConfig.fromEnv(), permanent: true);
    Get.lazyPut<http.Client>(() => http.Client(), fenix: true);
    Get.lazyPut<OpenAIService>(
      () => OpenAIService(
        client: Get.find<http.Client>(),
        config: Get.find<EnvironmentConfig>(),
      ),
      fenix: true,
    );
    Get.put<FirebaseAuth>(FirebaseAuth.instance, permanent: true);
    Get.put<FirebaseFirestore>(FirebaseFirestore.instance, permanent: true);
    Get.put<GoogleSignIn>(
      GoogleSignIn.instance,
      permanent: true,
    );
    Get.lazyPut<AuthService>(
      () => AuthService(
        firebaseAuth: Get.find<FirebaseAuth>(),
        googleSignIn: Get.find<GoogleSignIn>(),
        firestore: Get.find<FirebaseFirestore>(),
      ),
      fenix: true,
    );
  }
}
