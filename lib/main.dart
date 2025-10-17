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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await FirebaseInitializer.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPreferences, permanent: true);

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

  runApp(const ReceitagoraApp());
}
