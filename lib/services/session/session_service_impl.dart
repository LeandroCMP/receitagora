import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/models/user_model.dart';
import 'package:receitagora/services/config/usage_config.dart';
import 'package:receitagora/services/config/usage_config_service.dart';

import 'session_service.dart';

class SessionServiceImpl extends GetxService implements SessionService {
  SessionServiceImpl({
    required SharedPreferences preferences,
    required UsageConfigService usageConfigService,
  })  : _preferences = preferences,
        _usageConfigService = usageConfigService,
        _readyCompleter = Completer<void>();

  final SharedPreferences _preferences;
  final UsageConfigService _usageConfigService;

  static const _modeKey = 'session.mode';
  static const _userJsonKey = 'session.user.data';
  static const _userIdKey = 'session.user.id';
  static const _userNameKey = 'session.user.name';
  static const _userEmailKey = 'session.user.email';
  static const _userAvatarKey = 'session.user.avatar';
  static const _profileCompletedKey = 'session.user.profileCompleted';
  static const _guestRecipeCountKey = 'session.guest.recipes.count';
  static const _guestRecipePeriodKey = 'session.guest.recipes.period';
  static const _guestLegacyCountKey = 'session.guest.count';
  static const _guestLegacyDateKey = 'session.guest.date';
  static const _authRecipeCountKey = 'session.auth.recipes.count';
  static const _authRecipePeriodKey = 'session.auth.recipes.period';
  static const _shareCountKey = 'session.share.count';
  static const _sharePeriodKey = 'session.share.period';
  static const _shareLegacyDateKey = 'session.share.date';

  final Completer<void> _readyCompleter;
  bool _isInitializing = false;
  final Rxn<UserMode> _mode = Rxn<UserMode>();
  final Rxn<UserModel> _user = Rxn<UserModel>();
  final RxInt _guestRecipeCount = 0.obs;
  final RxInt _authenticatedRecipeCount = 0.obs;
  final RxInt _shareCount = 0.obs;
  final RxInt _guestMonthlyLimit =
      SessionService.defaultGuestMonthlyLimit.obs;
  final RxInt _guestRecipeLimit =
      SessionService.defaultGuestRecipeLimit.obs;
  final RxInt _authenticatedMonthlyLimit =
      SessionService.defaultAuthenticatedMonthlyLimit.obs;
  final RxInt _shareMonthlyLimit =
      SessionService.defaultShareMonthlyLimit.obs;
  StreamSubscription<UsageConfig>? _configSubscription;

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
  bool get hasCompletedProfileSetup => _user.value?.profileCompleted ?? false;

  @override
  int get guestMonthlyLimit => _guestMonthlyLimit.value;

  @override
  int get guestRecipeLimit => _guestRecipeLimit.value;

  @override
  int get authenticatedMonthlyLimit => _authenticatedMonthlyLimit.value;

  @override
  int get shareMonthlyLimit => _shareMonthlyLimit.value;

  @override
  int get guestRecipeCount => _guestRecipeCount.value;

  @override
  int get guestRecipesRemaining {
    final remaining = _guestMonthlyLimit.value - _guestRecipeCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  int get authenticatedRecipeCount => _authenticatedRecipeCount.value;

  @override
  int get authenticatedRecipesRemaining {
    final remaining =
        _authenticatedMonthlyLimit.value - _authenticatedRecipeCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  int get shareCount => _shareCount.value;

  @override
  int get sharesRemaining {
    final remaining = _shareMonthlyLimit.value - _shareCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Stream<UserMode?> get modeStream => _mode.stream;

  @override
  Stream<UserModel?> get userStream => _user.stream;

  @override
  Stream<int> get guestRecipeCountStream => _guestRecipeCount.stream;

  @override
  Stream<int> get shareCountStream => _shareCount.stream;

  @override
  Stream<int> get guestMonthlyLimitStream => _guestMonthlyLimit.stream;

  @override
  Stream<int> get guestRecipeLimitStream => _guestRecipeLimit.stream;

  @override
  Stream<int> get authenticatedRecipeCountStream =>
      _authenticatedRecipeCount.stream;

  @override
  Stream<int> get authenticatedMonthlyLimitStream =>
      _authenticatedMonthlyLimit.stream;

  @override
  Stream<int> get shareMonthlyLimitStream => _shareMonthlyLimit.stream;

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
      _ensureGuestRecipeQuotaFreshness();
      _ensureAuthenticatedRecipeQuotaFreshness();
      _ensureShareQuotaFreshness();
      await _initializeUsageConfig();

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
    _ensureGuestRecipeQuotaFreshness();
    _ensureShareQuotaFreshness();
  }

  @override
  Future<void> startAuthenticatedSession(UserModel user) async {
    _mode.value = UserMode.authenticated;
    final previousUserId = _preferences.getString(_userIdKey);
    await _persistUser(user);
    await _preferences.setString(_modeKey, UserMode.authenticated.name);
    if (previousUserId == null || previousUserId != user.id) {
      await _resetAuthenticatedUsage();
    }
    _guestRecipeCount.value = 0;
    await _preferences.remove(_guestRecipeCountKey);
    await _preferences.remove(_guestRecipePeriodKey);
    _ensureAuthenticatedRecipeQuotaFreshness();
    _ensureShareQuotaFreshness();
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
    await _preferences.remove(_guestRecipeCountKey);
    await _preferences.remove(_guestRecipePeriodKey);
    await _preferences.remove(_authRecipeCountKey);
    await _preferences.remove(_authRecipePeriodKey);
    await _preferences.remove(_shareCountKey);
    await _preferences.remove(_sharePeriodKey);
    _guestRecipeCount.value = 0;
    _authenticatedRecipeCount.value = 0;
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
  bool canGenerateGuestRecipes({int forCount = 1}) {
    if (!isGuest) {
      return true;
    }

    _ensureGuestRecipeQuotaFreshness();
    return guestRecipesRemaining >= forCount;
  }

  @override
  bool canGenerateAuthenticatedRecipes({int forCount = 1}) {
    if (!isAuthenticated) {
      return false;
    }

    _ensureAuthenticatedRecipeQuotaFreshness();
    return authenticatedRecipesRemaining >= forCount;
  }

  @override
  Future<void> registerGuestRecipes(int generatedCount) async {
    if (!isGuest || generatedCount <= 0) {
      return;
    }

    await ensureInitialized();
    _ensureGuestRecipeQuotaFreshness();
    final updated = _guestRecipeCount.value + generatedCount;
    _guestRecipeCount.value = updated;
    await _preferences.setInt(_guestRecipeCountKey, updated);
    await _preferences.setString(
      _guestRecipePeriodKey,
      _currentPeriodString(),
    );
  }

  @override
  Future<void> registerAuthenticatedRecipes(int generatedCount) async {
    if (!isAuthenticated || generatedCount <= 0) {
      return;
    }

    await ensureInitialized();
    _ensureAuthenticatedRecipeQuotaFreshness();
    final updated = _authenticatedRecipeCount.value + generatedCount;
    _authenticatedRecipeCount.value = updated;
    await _preferences.setInt(_authRecipeCountKey, updated);
    await _preferences.setString(
      _authRecipePeriodKey,
      _currentPeriodString(),
    );
  }

  @override
  bool canShareRecipe() {
    _ensureShareQuotaFreshness();
    return _shareCount.value < _shareMonthlyLimit.value;
  }

  @override
  Future<void> registerShare() async {
    await ensureInitialized();
    _ensureShareQuotaFreshness();
    final updated = _shareCount.value + 1;
    _shareCount.value = updated;
    await _preferences.setInt(_shareCountKey, updated);
    await _preferences.setString(
      _sharePeriodKey,
      _currentPeriodString(),
    );
  }

  @override
  void onClose() {
    _configSubscription?.cancel();
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

    final hasLegacyGuestCount = _preferences.containsKey(_guestLegacyCountKey);
    if (hasLegacyGuestCount) {
      await _preferences.remove(_guestLegacyCountKey);
    }
    final hasLegacyGuestDate = _preferences.containsKey(_guestLegacyDateKey);
    if (hasLegacyGuestDate) {
      await _preferences.remove(_guestLegacyDateKey);
    }
    if (_preferences.containsKey(_shareLegacyDateKey)) {
      await _preferences.remove(_shareLegacyDateKey);
    }

    _guestRecipeCount.value =
        _preferences.getInt(_guestRecipeCountKey) ?? 0;
    _authenticatedRecipeCount.value =
        _preferences.getInt(_authRecipeCountKey) ?? 0;
    _shareCount.value = _preferences.getInt(_shareCountKey) ?? 0;
  }

  void _ensureGuestRecipeQuotaFreshness() {
    final storedPeriod = _preferences.getString(_guestRecipePeriodKey);
    final currentPeriod = _currentPeriodString();

    if (storedPeriod == null || storedPeriod != currentPeriod) {
      _guestRecipeCount.value = 0;
      _preferences.setString(_guestRecipePeriodKey, currentPeriod);
      _preferences.setInt(_guestRecipeCountKey, 0);
    }
  }

  void _ensureShareQuotaFreshness() {
    final storedPeriod = _preferences.getString(_sharePeriodKey);
    final currentPeriod = _currentPeriodString();

    if (storedPeriod == null || storedPeriod != currentPeriod) {
      _shareCount.value = 0;
      _preferences.setString(_sharePeriodKey, currentPeriod);
      _preferences.setInt(_shareCountKey, 0);
    }
  }

  void _ensureAuthenticatedRecipeQuotaFreshness() {
    final storedPeriod = _preferences.getString(_authRecipePeriodKey);
    final currentPeriod = _currentPeriodString();

    if (storedPeriod == null || storedPeriod != currentPeriod) {
      _authenticatedRecipeCount.value = 0;
      _preferences.setString(_authRecipePeriodKey, currentPeriod);
      _preferences.setInt(_authRecipeCountKey, 0);
    }
  }

  Future<void> _resetAuthenticatedUsage() async {
    _authenticatedRecipeCount.value = 0;
    await _preferences.setInt(_authRecipeCountKey, 0);
    await _preferences.setString(
      _authRecipePeriodKey,
      _currentPeriodString(),
    );
    _shareCount.value = 0;
    await _preferences.setInt(_shareCountKey, 0);
    await _preferences.setString(
      _sharePeriodKey,
      _currentPeriodString(),
    );
  }

  String _currentPeriodString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
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
    if (_guestMonthlyLimit.value != config.guestMonthlyLimit) {
      _guestMonthlyLimit.value = config.guestMonthlyLimit;
      if (_guestRecipeCount.value > config.guestMonthlyLimit) {
        _guestRecipeCount.value = config.guestMonthlyLimit;
        unawaited(
          _preferences.setInt(_guestRecipeCountKey, _guestRecipeCount.value),
        );
      }
    }
    if (_guestRecipeLimit.value != config.guestRecipeLimit) {
      _guestRecipeLimit.value = config.guestRecipeLimit;
    }
    if (_authenticatedMonthlyLimit.value != config.authenticatedMonthlyLimit) {
      _authenticatedMonthlyLimit.value = config.authenticatedMonthlyLimit;
      if (_authenticatedRecipeCount.value > config.authenticatedMonthlyLimit) {
        _authenticatedRecipeCount.value = config.authenticatedMonthlyLimit;
        unawaited(
          _preferences.setInt(
            _authRecipeCountKey,
            _authenticatedRecipeCount.value,
          ),
        );
      }
    }
    if (_shareMonthlyLimit.value != config.shareMonthlyLimit) {
      _shareMonthlyLimit.value = config.shareMonthlyLimit;
      if (_shareCount.value > config.shareMonthlyLimit) {
        _shareCount.value = config.shareMonthlyLimit;
        unawaited(
          _preferences.setInt(_shareCountKey, _shareCount.value),
        );
      }
    }
  }
}
