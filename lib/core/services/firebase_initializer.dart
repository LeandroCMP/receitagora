import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Handles the one-time Firebase initialization for the application.
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;
  static Future<void>? _initializationFuture;
  static Future<void>? _probeFuture;

  /// Ensures Firebase is ready before the rest of the app bootstraps.
  ///
  /// If the native configuration (google-services.json / GoogleService-Info.plist)
  /// is not available yet, the error is logged and the app continues so the
  /// credential files can be added later without blocking execution.
  static Future<void> ensureInitialized() async {
    if (_probeFuture != null) {
      await _probeFuture;
      return;
    }

    _initializationFuture ??= _initializeFirebase();

    try {
      await _initializationFuture;
    } finally {
      if (!_initialized) {
        _initializationFuture = null;
      }
    }

    if (!_initialized) {
      debugPrint('Firebase not initialized; skipping integration probe.');
      return;
    }

    _probeFuture ??= _writeIntegrationProbe();
    await _probeFuture;
  }

  static Future<void> _writeIntegrationProbe() async {
    try {
      final firestore = FirebaseFirestore.instanceFor(app: Firebase.app());
      await firestore.collection('integration_tests').doc('bootstrap_probe').set(
        {
          'status': 'ok',
          'checkedAt': FieldValue.serverTimestamp(),
          'platform': _currentPlatformName(),
          'buildMode': kReleaseMode ? 'release' : 'debug',
          'source': 'receitagora_bootstrap',
        },
        SetOptions(merge: true),
      );
      debugPrint('Firebase integration test document recorded successfully.');
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Firebase integration test failed: ${error.code} -> ${error.message}\n$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase integration test error: $error\n$stackTrace');
    }
  }

  static Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Firebase initialization skipped: ${error.code} -> ${error.message}\n$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization error: $error\n$stackTrace');
    }
  }

  static String _currentPlatformName() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }

    return 'unknown';
  }
}
