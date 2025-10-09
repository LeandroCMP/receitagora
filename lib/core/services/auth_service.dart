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
  Future<void>? _googleSignInInitialization;
  SessionService get sessionService => Get.find<SessionService>();

  Future<SessionUser> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final account = await googleSignIn.authenticate();

      final authTokens = account.authentication;
      final idToken = authTokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthFailure.message(
          'Não foi possível obter o token de autenticação da sua conta Google.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
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
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure.cancelled();
      }
      throw AuthFailure.message(_translateGoogleSignInError(error));
    } on UnsupportedError {
      throw AuthFailure.message(
        'O login com Google não está disponível para esta plataforma no momento.',
      );
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
    final document = firestore.collection('users').doc(user.id);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);

      final data = <String, dynamic>{
        'name': user.displayName,
        'email': user.email,
        if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
          'avatarUrl': user.avatarUrl,
        'provider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(document, data, SetOptions(merge: true));
    });
  }

  String _translateGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.interrupted:
        return 'A autenticação foi interrompida. Tente novamente.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Configuração inválida do login com Google. Verifique suas credenciais.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Não foi possível iniciar o login com Google. Tente novamente em instantes.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Não conseguimos exibir a tela do Google para finalizar o login.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'A conta informada não corresponde à sessão atual. Tente novamente.';
      case GoogleSignInExceptionCode.canceled:
        return 'O login com Google foi cancelado.';
      case GoogleSignInExceptionCode.unknownError:
        break;
    }

    final description = error.description?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }
    return 'Ocorreu um erro inesperado ao validar o login com Google.';
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

  Future<void> _ensureGoogleSignInInitialized() async {
    final existing = _googleSignInInitialization;
    if (existing != null) {
      await existing;
      return;
    }

    final future = googleSignIn.initialize();
    _googleSignInInitialization = future;

    try {
      await future;
    } catch (error) {
      _googleSignInInitialization = null;
      rethrow;
    }
  }
}
