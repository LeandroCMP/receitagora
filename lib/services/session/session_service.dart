import 'package:receitagora/models/subscription_plan.dart';
import 'package:receitagora/models/user_model.dart';

enum UserMode { guest, authenticated }

abstract class SessionService {
  static const int defaultGuestDailyLimit = 2;
  static const int defaultGuestRecipeLimit = 2;
  static const int defaultShareDailyLimit = 50;

  Future<void> get ready;

  UserMode? get mode;
  bool get hasActiveSession;
  bool get isGuest;
  bool get isAuthenticated;
  UserModel? get user;
  SubscriptionPlan? get plan;
  bool get hasCompletedProfileSetup;
  bool get hasPremiumAccess;
  int get guestDailyLimit;
  int get guestRecipeLimit;
  int get shareDailyLimit;
  int get guestSearchCount;
  int get guestSearchesRemaining;
  int get shareCount;
  int get sharesRemaining;

  Stream<UserMode?> get modeStream;
  Stream<UserModel?> get userStream;
  Stream<SubscriptionPlan?> get planStream;
  Stream<int> get guestSearchCountStream;
  Stream<int> get shareCountStream;
  Stream<int> get guestDailyLimitStream;
  Stream<int> get guestRecipeLimitStream;
  Stream<int> get shareDailyLimitStream;

  Future<SessionService> init();
  Future<void> ensureInitialized();
  Future<void> continueAsGuest();
  Future<void> startAuthenticatedSession(UserModel user);
  Future<void> clearSession();
  Future<void> updateDisplayName(String displayName);
  Future<void> updateProfile(UserModel user);
  Future<void> refreshSubscriptionPlan();
  bool canPerformGuestSearch();
  Future<void> registerGuestSearch();
  bool canShareRecipe();
  Future<void> registerShare();
}
