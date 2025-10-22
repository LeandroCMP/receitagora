import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:receitagora/firebase_options.dart';

/// Handles the one-time Firebase initialization for the application.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;
  static bool _hasLoggedResolvedOptions = false;

  /// Ensures Firebase is ready before the rest of the app bootstraps.
  ///
  /// If the native configuration (google-services.json / GoogleService-Info.plist)
  /// is not available yet, the error is logged and the app continues so the
  /// credential files can be added later without blocking execution.
  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      _logResolvedOptions(Firebase.apps.first.options);
      _initialized = true;
      return;
    }

    try {
      final FirebaseOptions options = kIsWeb
          ? DefaultFirebaseOptions.web
          : DefaultFirebaseOptions.currentPlatform;

      final FirebaseApp app = await Firebase.initializeApp(options: options);
      _logResolvedOptions(app.options);
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

  static void _logResolvedOptions(FirebaseOptions options) {
    if (_hasLoggedResolvedOptions) {
      return;
    }

    final String redactedKey = _redact(options.apiKey);
    debugPrint(
      'Firebase inicializado com sucesso. projectId=${options.projectId}, '
      'appId=${options.appId}, senderId=${options.messagingSenderId}, '
      'storageBucket=${options.storageBucket ?? 'n/a'}.',
    );
    debugPrint('Chave de API do Google Services: $redactedKey');
    _hasLoggedResolvedOptions = true;
  }

  static String _redact(String value) {
    if (value.isEmpty) {
      return '(vazio)';
    }

    if (value.length <= 8) {
      final String start = value.substring(0, 1);
      final String end = value.substring(value.length - 1);
      return '$start***$end';
    }

    final String start = value.substring(0, 4);
    final String end = value.substring(value.length - 4);
    return '$start***$end';
  }
}
