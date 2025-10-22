import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/application/app.dart';
import 'package:receitagora/core/services/firebase_initializer.dart';
import 'package:receitagora/services/config/usage_config_service.dart';
import 'package:receitagora/services/config/usage_config_service_impl.dart';
import 'package:receitagora/services/session/session_service.dart';
import 'package:receitagora/services/session/session_service_impl.dart';
import 'package:receitagora/services/billing/billing_service.dart';
import 'package:receitagora/services/billing/stripe_billing_service.dart';
import 'package:receitagora/services/app/app_lifecycle_service.dart';
import 'package:receitagora/services/notifications/local_notification_service.dart';
import 'package:receitagora/services/usage/app_usage_service.dart';
import 'package:receitagora/services/usage/app_usage_service_impl.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service.dart';
import 'package:receitagora/services/shopping_list/shopping_list_service_impl.dart';
import 'package:receitagora/services/skill/skill_journey_service.dart';
import 'package:receitagora/services/skill/skill_journey_service_impl.dart';
import 'package:receitagora/services/wellness/wellness_routine_service.dart';
import 'package:receitagora/services/wellness/wellness_routine_service_impl.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service.dart';
import 'package:receitagora/services/recipe/notebooks/favorites_notebook_service_impl.dart';
import 'package:receitagora/services/wellness/mood_journal_service.dart';
import 'package:receitagora/services/wellness/mood_journal_service_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await FirebaseInitializer.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPreferences, permanent: true);

  final usageService = AppUsageServiceImpl(preferences: sharedPreferences);
  await usageService.ensureInitialized();
  Get.put<AppUsageService>(usageService, permanent: true);

  final shoppingListService =
      ShoppingListServiceImpl(preferences: sharedPreferences);
  Get.put<ShoppingListService>(shoppingListService, permanent: true);

  final moodJournalService =
      MoodJournalServiceImpl(preferences: sharedPreferences);
  await moodJournalService.ensureInitialized();
  Get.put<MoodJournalService>(moodJournalService, permanent: true);

  final skillJourneyService = SkillJourneyServiceImpl();
  Get.put<SkillJourneyService>(skillJourneyService, permanent: true);

  final notificationService = LocalNotificationService();
  await notificationService.init();
  Get.put<LocalNotificationService>(notificationService, permanent: true);

  final lifecycleService = AppLifecycleService(
    usageService: usageService,
    notificationService: notificationService,
  );
  await lifecycleService.init();
  Get.put<AppLifecycleService>(lifecycleService, permanent: true);

  final wellnessRoutineService = WellnessRoutineServiceImpl(
    preferences: sharedPreferences,
    notificationService: notificationService,
  );
  Get.put<WellnessRoutineService>(wellnessRoutineService, permanent: true);

  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instance;
  final googleSignIn = GoogleSignIn.instance;
  Get.put<FirebaseAuth>(firebaseAuth, permanent: true);
  Get.put<FirebaseFirestore>(firestore, permanent: true);
  Get.put<FirebaseFunctions>(functions, permanent: true);
  Get.put<GoogleSignIn>(googleSignIn, permanent: true);

  final usageConfigService = UsageConfigServiceImpl(firestore: firestore);
  await usageConfigService.ensureInitialized();
  Get.put<UsageConfigService>(usageConfigService, permanent: true);

  final sessionService = SessionServiceImpl(
    preferences: sharedPreferences,
    usageConfigService: usageConfigService,
    firestore: firestore,
  );
  await sessionService.ensureInitialized();
  Get.put<SessionService>(sessionService, permanent: true);

  final billingService = StripeBillingService(functions: functions);
  await billingService.ensureInitialized();
  Get.put<BillingService>(billingService, permanent: true);

  final notebooksService = FavoritesNotebookServiceImpl(
    firestore: firestore,
    firebaseAuth: firebaseAuth,
    sessionService: sessionService,
  );
  Get.put<FavoritesNotebookService>(notebooksService, permanent: true);

  runApp(const ReceitagoraApp());
}
