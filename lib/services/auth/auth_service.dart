import 'package:receitagora/models/user_model.dart';

class AuthFailure implements Exception {
  const AuthFailure._(this.message, {this.isCancelled = false});

  final String message;
  final bool isCancelled;

  factory AuthFailure.message(String message) => AuthFailure._(message);

  factory AuthFailure.cancelled() => const AuthFailure._('', isCancelled: true);
}

abstract class AuthService {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> updateDisplayName(String newName);
}
