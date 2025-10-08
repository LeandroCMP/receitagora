import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      await Firebase.initializeApp();
      _initialized = true;
      await _writeIntegrationProbe();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Firebase initialization skipped: ${error.code} -> ${error.message}\n$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization error: $error\n$stackTrace');
    }
  }

  static Future<void> _writeIntegrationProbe() async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('integration_tests').add({
        'status': 'ok',
        'createdAt': Timestamp.now(),
        'source': 'receitagora_bootstrap',
      });
      debugPrint('Firebase integration test document created successfully.');
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Firebase integration test failed: ${error.code} -> ${error.message}\n$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase integration test error: $error\n$stackTrace');
    }
  }
}
