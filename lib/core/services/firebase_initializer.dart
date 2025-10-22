import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:receitagora/firebase_options.dart';

/// Handles the one-time Firebase initialization for the application.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;

  /// Ensures Firebase is ready before the rest of the app bootstraps.
  ///
  /// If the native configuration (google-services.json / GoogleService-Info.plist)
  /// is not available yet, the error is logged and the app continues so the
  /// credential files can be added later without blocking execution.
  static Future<void> ensureInitialized() async {
    if (_initialized || Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.web,
        );
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
    } on FirebaseException catch (error, stackTrace) {
      _initialized = false;
      debugPrint(
        'Firebase initialization failed: ${error.code} -> ${error.message}\n$stackTrace',
      );
      rethrow;
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Firebase initialization error: $error\n$stackTrace');
      rethrow;
    }
  }
}
