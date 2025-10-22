import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:receitagora/services/notifications/local_notification_service.dart';
import 'package:receitagora/services/usage/app_usage_service.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  AppLifecycleService({
    required AppUsageService usageService,
    required LocalNotificationService notificationService,
  })  : _usageService = usageService,
        _notificationService = notificationService;

  final AppUsageService _usageService;
  final LocalNotificationService _notificationService;

  bool _registeredObserver = false;
  bool _notifiedOpen = false;
  DateTime? _lastRegistration;
  Completer<void>? _initializing;

  Future<AppLifecycleService> init() async {
    if (_initializing != null) {
      return _initializing!.future.then((_) => this);
    }

    final completer = Completer<void>();
    _initializing = completer;
    final binding = WidgetsBinding.instance;
    if (!_registeredObserver) {
      binding.addObserver(this);
      _registeredObserver = true;
    }

    try {
      await _handleResumeEvent();
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      _initializing = null;
      rethrow;
    }

    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_handleResumeEvent());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.paused:
        unawaited(_scheduleClosedAppTest());
        break;
    }
  }

  Future<void> _handleResumeEvent() async {
    final now = DateTime.now();
    if (_lastRegistration != null &&
        now.difference(_lastRegistration!) < const Duration(seconds: 10)) {
      return;
    }

    _lastRegistration = now;

    try {
      await _usageService.registerAppOpen(now: now);
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao registrar abertura do app: $error\n$stackTrace',
        isError: true,
      );
    }

    if (!_notifiedOpen) {
      _notifiedOpen = true;
      try {
        await _notificationService.notifyAppOpened();
      } catch (error, stackTrace) {
        Get.log(
          'Falha ao exibir notificação de teste: $error\n$stackTrace',
          isError: true,
        );
      }
    }

    try {
      await _notificationService.cancelAppClosedNotificationTest();
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao cancelar teste de app fechado: $error\n$stackTrace',
        isError: true,
      );
    }
  }

  Future<void> _scheduleClosedAppTest() async {
    try {
      await _notificationService.scheduleAppClosedNotificationTest();
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao agendar teste de app fechado: $error\n$stackTrace',
        isError: true,
      );
    }
  }

  @override
  void onClose() {
    if (_registeredObserver) {
      WidgetsBinding.instance.removeObserver(this);
      _registeredObserver = false;
    }
    super.onClose();
  }
}
