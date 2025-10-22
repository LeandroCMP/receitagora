import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/models/subscription_plan.dart';
import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/config/usage_config.dart';
import 'package:receitagora/services/config/usage_config_service.dart';

import 'session_service.dart';

class SessionServiceImpl extends GetxService implements SessionService {
  SessionServiceImpl({
    required SharedPreferences preferences,
    required UsageConfigService usageConfigService,
    required FirebaseFirestore firestore,
  })  : _preferences = preferences,
        _usageConfigService = usageConfigService,
        _firestore = firestore,
        _readyCompleter = Completer<void>();

  final SharedPreferences _preferences;
  final UsageConfigService _usageConfigService;
  final FirebaseFirestore _firestore;

  static const _modeKey = 'session.mode';
  static const _userJsonKey = 'session.user.data';
  static const _userIdKey = 'session.user.id';
  static const _userNameKey = 'session.user.name';
  static const _userEmailKey = 'session.user.email';
  static const _userAvatarKey = 'session.user.avatar';
  static const _profileCompletedKey = 'session.user.profileCompleted';
  static const _guestCountKey = 'session.guest.count';
  static const _guestDateKey = 'session.guest.date';
  static const _shareCountKey = 'session.share.count';
  static const _shareDateKey = 'session.share.date';
  static const _planCacheKey = 'session.plan.cache';
  static const _testerEmail = 'ins4nehs@gmail.com';

  final Completer<void> _readyCompleter;
  bool _isInitializing = false;
  final Rxn<UserMode> _mode = Rxn<UserMode>();
  final Rxn<UserModel> _user = Rxn<UserModel>();
  final Rxn<SubscriptionPlan> _plan = Rxn<SubscriptionPlan>();
  final RxInt _guestSearchCount = 0.obs;
  final RxInt _shareCount = 0.obs;
  final RxInt _guestDailyLimit =
      SessionService.defaultGuestDailyLimit.obs;
  final RxInt _guestRecipeLimit =
      SessionService.defaultGuestRecipeLimit.obs;
  final RxInt _shareDailyLimit =
      SessionService.defaultShareDailyLimit.obs;
  StreamSubscription<UsageConfig>? _configSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _planSubscription;
  String? _planUserId;

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  UserMode? get mode => _mode.value;

  @override
  bool get hasActiveSession => _mode.value != null;

  @override
  bool get isGuest => _mode.value == UserMode.guest;

  @override
  bool get isAuthenticated => _mode.value == UserMode.authenticated;

  @override
  UserModel? get user => _user.value;

  @override
  SubscriptionPlan? get plan => _plan.value;

  @override
  bool get hasCompletedProfileSetup => _user.value?.profileCompleted ?? false;

  @override
  bool get hasPremiumAccess => _plan.value?.isPremium ?? false;

  @override
  int get guestDailyLimit => _guestDailyLimit.value;

  @override
  int get guestRecipeLimit => _guestRecipeLimit.value;

  @override
  int get shareDailyLimit => _shareDailyLimit.value;

  @override
  int get guestSearchCount => _guestSearchCount.value;

  @override
  int get guestSearchesRemaining {
    final remaining = _guestDailyLimit.value - _guestSearchCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  int get shareCount => _shareCount.value;

  @override
  int get sharesRemaining {
    final remaining = _shareDailyLimit.value - _shareCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Stream<UserMode?> get modeStream => _mode.stream;

  @override
  Stream<UserModel?> get userStream => _user.stream;

  @override
  Stream<SubscriptionPlan?> get planStream => _plan.stream;

  @override
  Stream<int> get guestSearchCountStream => _guestSearchCount.stream;

  @override
  Stream<int> get shareCountStream => _shareCount.stream;

  @override
  Stream<int> get guestDailyLimitStream => _guestDailyLimit.stream;

  @override
  Stream<int> get guestRecipeLimitStream => _guestRecipeLimit.stream;

  @override
  Stream<int> get shareDailyLimitStream => _shareDailyLimit.stream;

  @override
  Future<SessionService> init() async {
    await ensureInitialized();
    return this;
  }

  @override
  Future<void> ensureInitialized() async {
    if (_readyCompleter.isCompleted) {
      return;
    }

    if (_isInitializing) {
      await ready;
      return;
    }

    _isInitializing = true;

    try {
      await _hydrateFromPreferences();
      await _clearLegacyFavoriteEntries();
      _ensureGuestQuotaFreshness();
      _ensureShareQuotaFreshness();
      await _initializeUsageConfig();
      if (isAuthenticated && _user.value != null) {
        await _ensureTesterPremiumAccessIfNeeded(_user.value!);
        await _listenToPlanChanges(_user.value!.id);
      } else {
        await _stopPlanTracking(clearPlan: true);
      }

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Future<void> continueAsGuest() async {
    _mode.value = UserMode.guest;
    _user.value = null;
    await _preferences.setString(_modeKey, UserMode.guest.name);
    await _preferences.remove(_userIdKey);
    await _preferences.remove(_userNameKey);
    await _preferences.remove(_userEmailKey);
    await _preferences.remove(_userAvatarKey);
    await _preferences.remove(_userJsonKey);
    await _preferences.remove(_profileCompletedKey);
    await _stopPlanTracking(clearPlan: true);
    _ensureGuestQuotaFreshness();
    _ensureShareQuotaFreshness();
  }

  @override
  Future<void> startAuthenticatedSession(UserModel user) async {
    _mode.value = UserMode.authenticated;
    await _persistUser(user);
    await _preferences.setString(_modeKey, UserMode.authenticated.name);
    _guestSearchCount.value = 0;
    await _preferences.remove(_guestCountKey);
    await _preferences.remove(_guestDateKey);
    _ensureShareQuotaFreshness();
    await _ensureTesterPremiumAccessIfNeeded(user);
    await _listenToPlanChanges(user.id);
  }

  @override
  Future<void> clearSession() async {
    _mode.value = null;
    _user.value = null;
    await _preferences.remove(_modeKey);
    await _preferences.remove(_userIdKey);
    await _preferences.remove(_userNameKey);
    await _preferences.remove(_userEmailKey);
    await _preferences.remove(_userAvatarKey);
    await _preferences.remove(_userJsonKey);
    await _preferences.remove(_profileCompletedKey);
    await _preferences.remove(_guestCountKey);
    await _preferences.remove(_guestDateKey);
    await _preferences.remove(_shareCountKey);
    await _preferences.remove(_shareDateKey);
    await _stopPlanTracking(clearPlan: true);
    _guestSearchCount.value = 0;
    _shareCount.value = 0;
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final sanitized = displayName.trim();
    if (sanitized.isEmpty) {
      return;
    }

    final current = _user.value;
    if (current == null) {
      return;
    }

    final updated = current.copyWith(name: sanitized);

    await updateProfile(updated);
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    _user.value = user;
    await _preferences.setString(_userJsonKey, user.toJson());
    await _preferences.setString(_userIdKey, user.id);
    await _preferences.setString(_userNameKey, user.name);
    await _preferences.setString(_userEmailKey, user.email);
    await _preferences.setBool(_profileCompletedKey, user.profileCompleted);

    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      await _preferences.setString(_userAvatarKey, user.avatarUrl!);
    } else {
      await _preferences.remove(_userAvatarKey);
    }
  }

  @override
  Future<void> refreshSubscriptionPlan() async {
    if (!isAuthenticated) {
      await _stopPlanTracking(clearPlan: true);
      return;
    }

    final userId = _user.value?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final currentUser = _user.value;
    if (currentUser != null) {
      await _ensureTesterPremiumAccessIfNeeded(currentUser);
    }
    await _listenToPlanChanges(userId);
  }

  @override
  @override
  bool canPerformGuestSearch() {
    if (!isGuest) {
      return true;
    }

    _ensureGuestQuotaFreshness();
    return _guestSearchCount.value < _guestDailyLimit.value;
  }

  @override
  Future<void> registerGuestSearch() async {
    if (!isGuest) {
      return;
    }

    _ensureGuestQuotaFreshness();
    final updated = _guestSearchCount.value + 1;
    _guestSearchCount.value = updated;
    await _preferences.setInt(_guestCountKey, updated);
    await _preferences.setString(
      _guestDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  bool canShareRecipe() {
    _ensureShareQuotaFreshness();
    return _shareCount.value < _shareDailyLimit.value;
  }

  @override
  Future<void> registerShare() async {
    await ensureInitialized();
    _ensureShareQuotaFreshness();
    final updated = _shareCount.value + 1;
    _shareCount.value = updated;
    await _preferences.setInt(_shareCountKey, updated);
    await _preferences.setString(
      _shareDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  void onClose() {
    _configSubscription?.cancel();
    _planSubscription?.cancel();
    super.onClose();
  }

  Future<void> _hydrateFromPreferences() async {
    _mode.value = _parseMode(_preferences.getString(_modeKey));

    if (isAuthenticated) {
      final json = _preferences.getString(_userJsonKey);
      if (json != null && json.isNotEmpty) {
        try {
          _user.value = UserModel.fromJson(json);
        } catch (_) {
          await _preferences.remove(_userJsonKey);
        }
      }

      if (_user.value == null) {
        final id = _preferences.getString(_userIdKey);
        final name = _preferences.getString(_userNameKey);
        final email = _preferences.getString(_userEmailKey);
        final avatar = _preferences.getString(_userAvatarKey);
        final completed = _preferences.getBool(_profileCompletedKey) ?? false;
        if (email != null && id != null) {
          _user.value = UserModel(
            id: id,
            name: (name == null || name.isEmpty) ? email : name,
            email: email,
            avatarUrl: avatar,
            profileCompleted: completed,
          );
        }
      }
    }

    _guestSearchCount.value = _preferences.getInt(_guestCountKey) ?? 0;
    _shareCount.value = _preferences.getInt(_shareCountKey) ?? 0;

    final planJson = _preferences.getString(_planCacheKey);
    if (planJson != null && planJson.isNotEmpty) {
      try {
        final cachedPlan = SubscriptionPlan.fromJson(planJson);
        _plan.value = cachedPlan.isExpired ? null : cachedPlan;
      } catch (_) {
        await _preferences.remove(_planCacheKey);
      }
    }
  }

  void _ensureGuestQuotaFreshness() {
    final storedDateString = _preferences.getString(_guestDateKey);
    final now = DateTime.now();

    if (storedDateString == null) {
      _guestSearchCount.value = 0;
      _preferences.setString(_guestDateKey, now.toIso8601String());
      _preferences.setInt(_guestCountKey, 0);
      return;
    }

    final storedDate = DateTime.tryParse(storedDateString);
    if (storedDate == null || !_isSameDay(storedDate, now)) {
      _guestSearchCount.value = 0;
      _preferences.setString(_guestDateKey, now.toIso8601String());
      _preferences.setInt(_guestCountKey, 0);
    }
  }

  void _ensureShareQuotaFreshness() {
    final storedDateString = _preferences.getString(_shareDateKey);
    final now = DateTime.now();

    if (storedDateString == null) {
      _shareCount.value = 0;
      _preferences.setString(_shareDateKey, now.toIso8601String());
      _preferences.setInt(_shareCountKey, 0);
      return;
    }

    final storedDate = DateTime.tryParse(storedDateString);
    if (storedDate == null || !_isSameDay(storedDate, now)) {
      _shareCount.value = 0;
      _preferences.setString(_shareDateKey, now.toIso8601String());
      _preferences.setInt(_shareCountKey, 0);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _clearLegacyFavoriteEntries() async {
    final keys = Set<String>.from(_preferences.getKeys());
    if (keys.isEmpty) {
      return;
    }

    const legacyPatterns = <String>[
      'favorite',
      'favorites',
      'recipeFavorites',
    ];

    for (final key in keys) {
      final matchesPattern = legacyPatterns.any(key.contains);
      if (matchesPattern) {
        await _preferences.remove(key);
      }
    }
  }

  UserMode? _parseMode(String? value) {
    if (value == null) {
      return null;
    }

    return UserMode.values.firstWhereOrNull((mode) => mode.name == value);
  }

  Future<void> _persistUser(UserModel user) async {
    await updateProfile(user);
  }

  Future<void> _initializeUsageConfig() async {
    await _usageConfigService.ensureInitialized();
    _applyUsageConfig(_usageConfigService.current);
    _configSubscription ??=
        _usageConfigService.stream.listen(_applyUsageConfig);
  }

  void _applyUsageConfig(UsageConfig config) {
    if (_guestDailyLimit.value != config.guestDailyLimit) {
      _guestDailyLimit.value = config.guestDailyLimit;
      if (_guestSearchCount.value > config.guestDailyLimit) {
        _guestSearchCount.value = config.guestDailyLimit;
        unawaited(
          _preferences.setInt(_guestCountKey, _guestSearchCount.value),
        );
      }
    }
    if (_guestRecipeLimit.value != config.guestRecipeLimit) {
      _guestRecipeLimit.value = config.guestRecipeLimit;
    }
    if (_shareDailyLimit.value != config.shareDailyLimit) {
      _shareDailyLimit.value = config.shareDailyLimit;
      if (_shareCount.value > config.shareDailyLimit) {
        _shareCount.value = config.shareDailyLimit;
        unawaited(
          _preferences.setInt(_shareCountKey, _shareCount.value),
        );
      }
    }
  }

  Future<void> _listenToPlanChanges(String userId) async {
    if (userId.isEmpty) {
      await _stopPlanTracking(clearPlan: true);
      return;
    }

    if (_planUserId == userId && _planSubscription != null) {
      await _fetchPlanSnapshot(userId);
      return;
    }

    await _planSubscription?.cancel();
    _planUserId = userId;

    final docRef =
        _firestore.collection('users').doc(userId).collection('billing').doc('plan');

    _planSubscription = docRef.snapshots().listen(
      (snapshot) {
        _applyPlanSnapshot(snapshot.data());
      },
      onError: (_) {},
    );

    await _fetchPlanSnapshot(userId);
  }

  Future<void> _fetchPlanSnapshot(String userId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('billing')
          .doc('plan');
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        final currentUser = _user.value;
        if (currentUser != null) {
          await _ensureTesterPremiumAccessIfNeeded(currentUser);
          final refreshed = await docRef.get();
          _applyPlanSnapshot(refreshed.data());
          return;
        }
      }
      _applyPlanSnapshot(doc.data());
    } on FirebaseException {
      // Ignore transient errors; cached plan remains.
    }
  }

  SubscriptionPlan? _applyPlanSnapshot(Map<String, dynamic>? data) {
    if (data == null) {
      _plan.value = null;
      unawaited(_preferences.remove(_planCacheKey));
      return null;
    }

    try {
      final parsed = SubscriptionPlan.fromMap(data);
      if (parsed.isExpired) {
        _plan.value = null;
        unawaited(_preferences.remove(_planCacheKey));
        return null;
      } else {
        _plan.value = parsed;
        unawaited(_preferences.setString(_planCacheKey, parsed.toJson()));
        return parsed;
      }
    } catch (_) {
      // Ignore invalid payloads but clear cache to avoid stale data.
      _plan.value = null;
      unawaited(_preferences.remove(_planCacheKey));
      return null;
    }
  }

  Future<void> _stopPlanTracking({bool clearPlan = false}) async {
    _planUserId = null;
    await _planSubscription?.cancel();
    _planSubscription = null;
    if (clearPlan) {
      _plan.value = null;
      await _preferences.remove(_planCacheKey);
    }
  }

  Future<void> _ensureTesterPremiumAccessIfNeeded(UserModel user) async {
    final normalizedEmail = user.email.trim().toLowerCase();
    if (normalizedEmail != _testerEmail) {
      return;
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.id)
        .collection('billing')
        .doc('plan');

    try {
      final snapshot = await docRef.get();
      SubscriptionPlan? currentPlan;
      final data = snapshot.data();
      if (data != null) {
        try {
          currentPlan = SubscriptionPlan.fromMap(data);
        } catch (_) {
          currentPlan = null;
        }
      }

      if (currentPlan != null && currentPlan.isPremium) {
        return;
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 365));

      final payload = <String, dynamic>{
        'type': SubscriptionPlanType.premium.name,
        'platform': 'tester',
        'status': 'active',
        'autoRenews': false,
        'productId': 'premium_tester',
        'priceId': 'premium_tester_monthly',
        'transactionId': 'tester-${now.millisecondsSinceEpoch}',
        'interval': 'month',
        'amount': 2000,
        'currency': 'BRL',
        'subscriptionId': 'tester-${user.id}',
        'customerId': user.id,
        'cancelAtPeriodEnd': false,
        'expiresAt': expiresAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final createdAt = data?['createdAt'];
      if (createdAt == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));
    } on FirebaseException {
      // Ignore promotion failures; tester can be retried later.
    }
  }

}
