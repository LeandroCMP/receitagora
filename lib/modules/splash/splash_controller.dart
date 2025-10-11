import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/session/session_service.dart';

class SplashController extends GetxController {
  SplashController({
    required this.sessionService,
    required this.firebaseAuth,
  });

  final SessionService sessionService;
  final FirebaseAuth firebaseAuth;

  @override
  void onReady() {
    super.onReady();
    _evaluateSessionAndNavigate();
  }

  Future<void> _evaluateSessionAndNavigate() async {
    final splashDelay = Future<void>.delayed(const Duration(milliseconds: 1200));

    await sessionService.ensureInitialized();

    final firebaseUser = firebaseAuth.currentUser;
    final hasFirebaseUser = firebaseUser != null;
    final hasStoredSession = sessionService.isAuthenticated && sessionService.user != null;

    if (hasFirebaseUser && !hasStoredSession) {
      final email = firebaseUser!.email;
      if (email != null && email.isNotEmpty) {
        final displayName = firebaseUser.displayName?.trim();
        await sessionService.startAuthenticatedSession(
          UserModel(
            id: firebaseUser.uid,
            name: displayName == null || displayName.isEmpty
                ? email
                : displayName,
            email: email,
            avatarUrl: firebaseUser.photoURL,
          ),
        );
      }
    } else if (!hasFirebaseUser && hasStoredSession) {
      await sessionService.clearSession();
    }

    final shouldOpenRecipes = firebaseAuth.currentUser != null &&
        sessionService.isAuthenticated &&
        sessionService.user != null;

    await splashDelay;

    if (shouldOpenRecipes) {
      Get.offAllNamed(AppRoutes.recipeFinder);
      return;
    }

    Get.offAllNamed(AppRoutes.login);
  }
}
