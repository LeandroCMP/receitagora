import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/models/user_model.dart';

import 'session_service.dart';

class SessionServiceImpl extends GetxService implements SessionService {
  SessionServiceImpl({required SharedPreferences preferences})
      : _preferences = preferences,
        _readyCompleter = Completer<void>();

  final SharedPreferences _preferences;

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

  final Completer<void> _readyCompleter;
  bool _isInitializing = false;
  final Rxn<UserMode> _mode = Rxn<UserMode>();
  final Rxn<UserModel> _user = Rxn<UserModel>();
  final RxInt _guestSearchCount = 0.obs;
  final RxInt _shareCount = 0.obs;

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
  int get guestSearchCount => _guestSearchCount.value;

  @override
  int get guestSearchesRemaining {
    final remaining = SessionService.guestDailyLimit - _guestSearchCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  int get shareCount => _shareCount.value;

  @override
  int get sharesRemaining {
    final remaining = SessionService.shareDailyLimit - _shareCount.value;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Stream<UserMode?> get modeStream => _mode.stream;

  @override
  Stream<UserModel?> get userStream => _user.stream;

  @override
  Stream<int> get guestSearchCountStream => _guestSearchCount.stream;

  @override
  Stream<int> get shareCountStream => _shareCount.stream;

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
  bool canPerformGuestSearch() {
    if (!isGuest) {
      return true;
    }

    _ensureGuestQuotaFreshness();
    return _guestSearchCount.value < SessionService.guestDailyLimit;
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
    return _shareCount.value < SessionService.shareDailyLimit;
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
}
