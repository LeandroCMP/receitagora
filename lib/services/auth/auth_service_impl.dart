import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  AuthServiceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
    required SessionService sessionService,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore,
        _sessionService = sessionService;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final SessionService _sessionService;

  Future<void>? _googleSignInInitialization;

  static const List<String> _scopeHint = <String>[
    'email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account =
          await _googleSignIn.authenticate(scopeHint: _scopeHint);

      final GoogleSignInAuthentication authTokens = account.authentication;
      final idToken = authTokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthFailure.message(
          'Não foi possível obter o token de autenticação da sua conta Google.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
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
      final user = UserModel(
        id: firebaseUser.uid,
        name: name == null || name.isEmpty ? email : name,
        email: email,
        avatarUrl: firebaseUser.photoURL,
      );

      await _sessionService.ensureInitialized();
      await _sessionService.startAuthenticatedSession(user);
      await _saveUserProfile(
        user: user,
        firebaseUser: firebaseUser,
        account: account,
      );

      return user;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure.cancelled();
      }
      throw AuthFailure.message(_translateGoogleSignInError(error));
    } on PlatformException catch (error) {
      throw AuthFailure.message(_translatePlatformError(error));
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

  @override
  Future<void> signOut() async {
    AuthFailure? failure;

    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } on GoogleSignInException catch (error) {
      failure ??= AuthFailure.message(_translateGoogleSignInError(error));
    } on PlatformException catch (error) {
      failure ??= AuthFailure.message(_translatePlatformError(error));
    } on UnsupportedError {
      failure ??=
          AuthFailure.message('O logout com Google não está disponível para esta plataforma.');
    }

    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      failure ??= AuthFailure.message(_translateFirebaseAuthError(error));
    }

    await _sessionService.ensureInitialized();
    await _sessionService.clearSession();

    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    final sanitized = newName.trim();
    if (sanitized.isEmpty) {
      throw AuthFailure.message('Informe um nome válido para continuar.');
    }

    try {
      await _sessionService.ensureInitialized();
      final currentUser = _firebaseAuth.currentUser;
      final sessionUser = _sessionService.user;

      if (currentUser == null || sessionUser == null) {
        throw AuthFailure.message('Nenhuma sessão autenticada foi encontrada.');
      }

      if (currentUser.displayName != sanitized) {
        await currentUser.updateDisplayName(sanitized);
        await currentUser.reload();
      }

      final document = _firestore.collection('users').doc(currentUser.uid);
      await document.set(
        <String, dynamic>{
          'displayName': sanitized,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _sessionService.updateDisplayName(sanitized);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.message(_translateFirebaseAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthFailure.message(_translateFirestoreError(error));
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??=
        _googleSignIn.initialize(scopes: _scopeHint);
  }

  Future<void> _saveUserProfile({
    required UserModel user,
    required User firebaseUser,
    required GoogleSignInAccount account,
  }) async {
    try {
      final document = _firestore.collection('users').doc(firebaseUser.uid);
      await document.set(
        <String, dynamic>{
          'displayName': user.name,
          'email': user.email,
          'photoUrl': user.avatarUrl,
          'emailVerified': firebaseUser.emailVerified,
          'phoneNumber': firebaseUser.phoneNumber,
          'providerId': firebaseUser.providerData.isNotEmpty
              ? firebaseUser.providerData.first.providerId
              : null,
          'metadata': {
            'creationTime': firebaseUser.metadata.creationTime?.toIso8601String(),
            'lastSignInTime': firebaseUser.metadata.lastSignInTime?.toIso8601String(),
          },
          'googleAccount': {
            'id': account.id,
            'email': account.email,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      throw AuthFailure.message(_translateFirestoreError(error));
    }
  }

  String _translateGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Login com Google cancelado pelo usuário.';
      case GoogleSignInExceptionCode.interrupted:
        return 'O login com Google foi interrompido. Tente novamente.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'A configuração do login com Google está incorreta. Revise as credenciais do Firebase.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Não foi possível exibir a interface do Google para concluir o login.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'A conta Google selecionada não corresponde à sessão atual.';
      case GoogleSignInExceptionCode.unknownError:
      default:
        final description = error.description;
        if (description != null && description.isNotEmpty) {
          return 'Ocorreu um erro inesperado durante o login com Google: $description';
        }
        return 'Ocorreu um erro inesperado durante o login com Google.';
    }
  }

  String _translatePlatformError(PlatformException error) {
    return 'Falha inesperada ao acessar o Google Sign-In (código: ${error.code}).';
  }

  String _translateFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-disabled':
        return 'A conta Google utilizada não está autorizada a acessar este aplicativo.';
      case 'operation-not-allowed':
        return 'O login com Google não está habilitado no projeto do Firebase.';
      default:
        return 'Erro inesperado ao autenticar com o Firebase (código: ${error.code}).';
    }
  }

  String _translateFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'O Firestore não permitiu salvar seu perfil. Verifique as regras de segurança do projeto.';
      case 'unavailable':
        return 'O Firestore está temporariamente indisponível. Tente novamente em instantes.';
      default:
        return 'Não foi possível atualizar seu perfil no Firestore (código: ${error.code}).';
    }
  }
}
