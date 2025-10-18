import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/core/config/environment_config.dart';
import 'package:receitagora/services/auth/auth_service.dart';
import 'package:receitagora/services/auth/auth_service_impl.dart';
import 'package:receitagora/services/openai/openai_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service.dart';
import 'package:receitagora/services/recipe/recipe_favorites_service_impl.dart';
import 'package:receitagora/services/recipe/recipe_history_service.dart';
import 'package:receitagora/services/recipe/recipe_history_service_impl.dart';
import 'package:receitagora/services/session/session_service.dart';
import 'package:receitagora/services/share/recipe_share_service.dart';
import 'package:receitagora/services/share/recipe_share_service_impl.dart';
import 'package:receitagora/services/ingredient_lab/ingredient_lab_service.dart';
import 'package:receitagora/services/nutrition/nutrition_plan_service.dart';

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
    if (!Get.isRegistered<FirebaseAuth>()) {
      Get.put<FirebaseAuth>(FirebaseAuth.instance, permanent: true);
    }
    if (!Get.isRegistered<FirebaseFirestore>()) {
      Get.put<FirebaseFirestore>(FirebaseFirestore.instance, permanent: true);
    }
    if (!Get.isRegistered<GoogleSignIn>()) {
      Get.put<GoogleSignIn>(
        GoogleSignIn.instance,
        permanent: true,
      );
    }
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
    Get.lazyPut<RecipeHistoryService>(
      () => RecipeHistoryServiceImpl(
        preferences: Get.find<SharedPreferences>(),
      ),
      fenix: true,
    );
    Get.lazyPut<RecipeShareService>(
      () => RecipeShareServiceImpl(
        sessionService: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<IngredientLabService>(
      () => IngredientLabService(
        openAIService: Get.find<OpenAIService>(),
        sessionService: Get.find<SessionService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<NutritionPlanService>(
      () => NutritionPlanService(
        firestore: Get.find<FirebaseFirestore>(),
        openAIService: Get.find<OpenAIService>(),
        sessionService: Get.find<SessionService>(),
      ),
      fenix: true,
    );
  }
}
