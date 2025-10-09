import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserMode { guest, authenticated }

class SessionUser {
  const SessionUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
}

class SessionService extends GetxService {
  SessionService({
    required this.preferences,
  }) : _readyCompleter = Completer<void>();
  final SharedPreferences preferences;

  static const _modeKey = 'session.mode';
  static const _userIdKey = 'session.user.id';
  static const _userNameKey = 'session.user.name';
  static const _userEmailKey = 'session.user.email';
  static const _userAvatarKey = 'session.user.avatar';
  static const _guestCountKey = 'session.guest.count';
  static const _guestDateKey = 'session.guest.date';

  static const int guestDailyLimit = 3;
  static const int guestRecipeLimit = 2;

  final Completer<void> _readyCompleter;
  bool _isInitializing = false;
  final Rxn<UserMode> _mode = Rxn<UserMode>();
  final Rxn<SessionUser> _user = Rxn<SessionUser>();
  final RxInt _guestSearchCount = 0.obs;

  Future<void> get ready => _readyCompleter.future;

  UserMode? get mode => _mode.value;
  bool get hasActiveSession => _mode.value != null;
  bool get isGuest => _mode.value == UserMode.guest;
  bool get isAuthenticated => _mode.value == UserMode.authenticated;
  SessionUser? get user => _user.value;
  int get guestSearchCount => _guestSearchCount.value;
  int get guestSearchesRemaining =>
      guestDailyLimit - _guestSearchCount.value < 0 ? 0 : guestDailyLimit - _guestSearchCount.value;

  Stream<UserMode?> get modeStream => _mode.stream;
  Stream<SessionUser?> get userStream => _user.stream;
  Stream<int> get guestSearchCountStream => _guestSearchCount.stream;

  Future<SessionService> init() async {
    await ensureInitialized();
    return this;
  }

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
      _ensureGuestQuotaFreshness();

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> continueAsGuest() async {
    _mode.value = UserMode.guest;
    _user.value = null;
    await preferences.setString(_modeKey, UserMode.guest.name);
    await preferences.remove(_userIdKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
    await preferences.remove(_userAvatarKey);
    _ensureGuestQuotaFreshness();
  }

  Future<void> startAuthenticatedSession(SessionUser user) async {
    _mode.value = UserMode.authenticated;
    _user.value = user;
    await preferences.setString(_modeKey, UserMode.authenticated.name);
    await preferences.setString(_userIdKey, user.id);
    await preferences.setString(_userNameKey, user.displayName);
    await preferences.setString(_userEmailKey, user.email);

    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      await preferences.setString(_userAvatarKey, user.avatarUrl!);
    } else {
      await preferences.remove(_userAvatarKey);
    }

    _guestSearchCount.value = 0;
    await preferences.remove(_guestCountKey);
    await preferences.remove(_guestDateKey);
  }

  Future<void> clearSession() async {
    _mode.value = null;
    _user.value = null;
    await preferences.remove(_modeKey);
    await preferences.remove(_userIdKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
    await preferences.remove(_userAvatarKey);
  }

  Future<void> updateDisplayName(String displayName) async {
    final sanitized = displayName.trim();
    if (sanitized.isEmpty) {
      return;
    }

    final current = _user.value;
    if (current == null) {
      return;
    }

    final updated = SessionUser(
      id: current.id,
      displayName: sanitized,
      email: current.email,
      avatarUrl: current.avatarUrl,
    );

    _user.value = updated;
    await preferences.setString(_userNameKey, sanitized);
  }

  bool canPerformGuestSearch() {
    if (!isGuest) {
      return true;
    }

    _ensureGuestQuotaFreshness();
    return _guestSearchCount.value < guestDailyLimit;
  }

  Future<void> registerGuestSearch() async {
    if (!isGuest) {
      return;
    }

    _ensureGuestQuotaFreshness();
    final updated = _guestSearchCount.value + 1;
    _guestSearchCount.value = updated;
    await preferences.setInt(_guestCountKey, updated);
    await preferences.setString(_guestDateKey, DateTime.now().toIso8601String());
  }

  Future<void> _hydrateFromPreferences() async {
    _mode.value = _parseMode(preferences.getString(_modeKey));

    if (isAuthenticated) {
      final id = preferences.getString(_userIdKey);
      final name = preferences.getString(_userNameKey);
      final email = preferences.getString(_userEmailKey);
      final avatar = preferences.getString(_userAvatarKey);
      if (email != null && id != null) {
        _user.value = SessionUser(
          id: id,
          displayName: (name == null || name.isEmpty) ? email : name,
          email: email,
          avatarUrl: avatar,
        );
      }
    }

    _guestSearchCount.value = preferences.getInt(_guestCountKey) ?? 0;
  }

  void _ensureGuestQuotaFreshness() {
    final storedDateString = preferences.getString(_guestDateKey);
    final now = DateTime.now();

    if (storedDateString == null) {
      _guestSearchCount.value = 0;
      preferences.setString(_guestDateKey, now.toIso8601String());
      preferences.setInt(_guestCountKey, 0);
      return;
    }

    final storedDate = DateTime.tryParse(storedDateString);
    if (storedDate == null || !_isSameDate(storedDate, now)) {
      _guestSearchCount.value = 0;
      preferences.setString(_guestDateKey, now.toIso8601String());
      preferences.setInt(_guestCountKey, 0);
    }
  }

  UserMode? _parseMode(String? value) {
    if (value == null) {
      return null;
    }

    for (final mode in UserMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return null;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
