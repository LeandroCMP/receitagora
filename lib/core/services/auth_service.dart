import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'session_service.dart';

class AuthFailure implements Exception {
  const AuthFailure._(this.message, {this.isCancelled = false});

  final String message;
  final bool isCancelled;

  factory AuthFailure.message(String message) => AuthFailure._(message);

  factory AuthFailure.cancelled() => const AuthFailure._('', isCancelled: true);
}

class AuthService extends GetxService {
  AuthService({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firestore,
  });

  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;
  SessionService get sessionService => Get.find<SessionService>();

  Future<SessionUser> signInWithGoogle() async {
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw AuthFailure.cancelled();
      }

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      final result = await firebaseAuth.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw AuthFailure.message(
          'Não foi possível obter os dados da sua conta Google.',
        );
      }

      final email = firebaseUser.email;
      if (email == null || email.isEmpty) {
        throw AuthFailure.message(
          'Não foi possível identificar o e-mail associado à sua conta Google.',
        );
      }

      final name = firebaseUser.displayName?.trim();
      final sessionUser = SessionUser(
        id: firebaseUser.uid,
        displayName: name == null || name.isEmpty ? email : name,
        email: email,
        avatarUrl: firebaseUser.photoURL,
      );

      await sessionService.ensureInitialized();
      await sessionService.startAuthenticatedSession(sessionUser);
      await _saveUserProfile(sessionUser);

      return sessionUser;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.message(_translateFirebaseAuthError(error));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw AuthFailure.message(
        'Não foi possível completar o login com Google. Tente novamente em instantes.',
      );
    }
  }

  Future<void> _saveUserProfile(SessionUser user) async {
    await firestore.collection('users').doc(user.id).set(
      {
        'displayName': user.displayName,
        'email': user.email,
        'avatarUrl': user.avatarUrl,
        'provider': 'google',
        'lastLoginAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _translateFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este e-mail usando outro método de login.';
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-disabled':
      case 'user-not-found':
        return 'Não foi possível validar sua conta Google. Tente novamente.';
      case 'operation-not-allowed':
        return 'O login com Google está temporariamente indisponível.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede e tente outra vez.';
      case 'popup-closed-by-user':
      case 'web-context-cancelled':
        return 'A janela de autenticação foi encerrada antes da conclusão.';
      default:
        final details = error.message?.trim();
        if (details != null && details.isNotEmpty) {
          return details;
        }
        return 'Ocorreu um erro inesperado ao validar o login com Google.';
    }
  }
}
