import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/app.dart';
import 'core/services/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await FirebaseInitializer.ensureInitialized();
  try {
    await GoogleSignIn.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Google Sign-In initialization failed: $error\n$stackTrace');
  }
  runApp(const ReceitagoraApp());
}
