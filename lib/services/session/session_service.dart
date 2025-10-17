import 'package:receitagora/models/user_model.dart';

enum UserMode { guest, authenticated }

abstract class SessionService {
  static const int defaultGuestMonthlyLimit = 10;
  static const int defaultGuestRecipeLimit = 2;
  static const int defaultAuthenticatedMonthlyLimit = 30;
  static const int defaultShareMonthlyLimit = 10;

  Future<void> get ready;

  UserMode? get mode;
  bool get hasActiveSession;
  bool get isGuest;
  bool get isAuthenticated;
  UserModel? get user;
  bool get hasCompletedProfileSetup;
  int get guestMonthlyLimit;
  int get guestRecipeLimit;
  int get authenticatedMonthlyLimit;
  int get shareMonthlyLimit;
  int get guestRecipeCount;
  int get guestRecipesRemaining;
  int get authenticatedRecipeCount;
  int get authenticatedRecipesRemaining;
  int get shareCount;
  int get sharesRemaining;

  Stream<UserMode?> get modeStream;
  Stream<UserModel?> get userStream;
  Stream<int> get guestRecipeCountStream;
  Stream<int> get shareCountStream;
  Stream<int> get guestMonthlyLimitStream;
  Stream<int> get guestRecipeLimitStream;
  Stream<int> get authenticatedRecipeCountStream;
  Stream<int> get authenticatedMonthlyLimitStream;
  Stream<int> get shareMonthlyLimitStream;

  Future<SessionService> init();
  Future<void> ensureInitialized();
  Future<void> continueAsGuest();
  Future<void> startAuthenticatedSession(UserModel user);
  Future<void> clearSession();
  Future<void> updateDisplayName(String displayName);
  Future<void> updateProfile(UserModel user);
  bool canGenerateGuestRecipes({int forCount = 1});
  bool canGenerateAuthenticatedRecipes({int forCount = 1});
  Future<void> registerGuestRecipes(int generatedCount);
  Future<void> registerAuthenticatedRecipes(int generatedCount);
  bool canShareRecipe();
  Future<void> registerShare();
}
