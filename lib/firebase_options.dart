import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Default Firebase configuration for the application.
///
/// The values were derived from the Android `google-services.json` bundled with
/// the project. If you add support for additional platforms (iOS, macOS, web,
/// etc.) remember to extend this file with the corresponding `FirebaseOptions`.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// Returns the [FirebaseOptions] for the current platform.
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase options for \'${defaultTargetPlatform.name}\' are not configured.',
        );
    }
  }

  /// Firebase configuration for web builds. The web app is currently not
  /// configured, so accessing this getter will throw until proper credentials
  /// are provided.
  static FirebaseOptions get web => throw UnsupportedError(
        'Firebase web configuration has not been provided.',
      );

  /// Android configuration pulled from `android/app/google-services.json`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1kr9roK7x2vsnaITT4SJF6sdDFT9Qb2s',
    appId: '1:652588029247:android:8f483eb1b5c1dbdaa2af8a',
    messagingSenderId: '652588029247',
    projectId: 'receitagora-7a6a2',
    storageBucket: 'receitagora-7a6a2.firebasestorage.app',
  );
}
