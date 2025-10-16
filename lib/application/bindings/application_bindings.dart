import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:receitagora/core/config/environment_config.dart';
import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/auth/auth_service_impl.dart';
import 'package:receitagora/services/openai/openai_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service_impl.dart';
import 'package:receitagora/services/session/session_service.dart';
import 'package:receitagora/services/share/recipe_share_service.dart';
import 'package:receitagora/services/share/recipe_share_service_impl.dart';

class ApplicationBindings extends Bindings {
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
      () => AuthServiceImpl(
        firebaseAuth: Get.find<FirebaseAuth>(),
        googleSignIn: Get.find<GoogleSignIn>(),
        firestore: Get.find<FirebaseFirestore>(),
        sessionService: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<RecipeFavoritesService>(
      () => RecipeFavoritesServiceImpl(
        firestore: Get.find<FirebaseFirestore>(),
        firebaseAuth: Get.find<FirebaseAuth>(),
      ),
      fenix: true,
    );
    Get.lazyPut<RecipeShareService>(
      () => RecipeShareServiceImpl(
        sessionService: Get.find<SessionService>(),
      ),
      fenix: true,
    );
  }
}
