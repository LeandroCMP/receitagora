import 'package:receitagora/models/user_model.dart';

enum UserMode { guest, authenticated }

abstract class SessionService {
  static const int guestDailyLimit = 2;
  static const int guestRecipeLimit = 2;
  static const int shareDailyLimit = 50;

  Future<void> get ready;

  UserMode? get mode;
  bool get hasActiveSession;
  bool get isGuest;
  bool get isAuthenticated;
  UserModel? get user;
  int get guestSearchCount;
  int get guestSearchesRemaining;
  int get shareCount;
  int get sharesRemaining;

  Stream<UserMode?> get modeStream;
  Stream<UserModel?> get userStream;
  Stream<int> get guestSearchCountStream;
  Stream<int> get shareCountStream;

  Future<SessionService> init();
  Future<void> ensureInitialized();
  Future<void> continueAsGuest();
  Future<void> startAuthenticatedSession(UserModel user);
  Future<void> clearSession();
  Future<void> updateDisplayName(String displayName);
  bool canPerformGuestSearch();
  Future<void> registerGuestSearch();
  bool canShareRecipe();
  Future<void> registerShare();
}
