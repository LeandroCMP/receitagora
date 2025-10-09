import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/firebase_initializer.dart';
import 'core/services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await FirebaseInitializer.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(sharedPreferences, permanent: true);

  final sessionService = SessionService(preferences: sharedPreferences);
  await sessionService.ensureInitialized();
  Get.put<SessionService>(sessionService, permanent: true);

  runApp(const ReceitagoraApp());
}
