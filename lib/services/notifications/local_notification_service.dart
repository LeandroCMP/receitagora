import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/services/notifications/device_timezone.dart';

class LocalNotificationService extends GetxService {
  LocalNotificationService();

  static const String _channelId = 'nutrition-plan-reminders';
  static const String _channelName = 'Lembretes do plano nutricional';
  static const String _channelDescription =
      'Alertas para check-ins e atualizações do plano premium.';
  static const int _checkInNotificationId = 7812;
  static const int _appOpenNotificationId = 7813;
  static const int _appClosedNotificationId = 7814;
  static const String _hydrationChannelId = 'hydration-coach';
  static const String _hydrationChannelName = 'Coach de hidratação';
  static const String _hydrationChannelDescription =
      'Lembretes automáticos para distribuição do consumo de água.';
  static const String _mindfulChannelId = 'mindful-break';
  static const String _mindfulChannelName = 'Pausa de bem-estar';
  static const String _mindfulChannelDescription =
      'Alertas para pausa consciente e alongamentos rápidos.';
  static const int _hydrationBaseId = 7820;
  static const int _hydrationMaxNotifications = 8;
  static const int _mindfulNotificationId = 7855;
  static const String _sleepChannelId = 'sleep-coach';
  static const String _sleepChannelName = 'Rotina de sono';
  static const String _sleepChannelDescription =
      'Lembretes noturnos para desacelerar e preparar o sono.';
  static const int _sleepNotificationId = 7860;
  static const String _digestChannelId = 'wellness-digest';
  static const String _digestChannelName = 'Resumo de bem-estar';
  static const String _digestChannelDescription =
      'Resumo automático com destaques de saúde do plano.';
  static const int _digestNotificationId = 7890;
  static const String _movementChannelId = 'movement-breaks';
  static const String _movementChannelName = 'Pausas ativas';
  static const String _movementChannelDescription =
      'Alertas para micro alongamentos e movimentação guiada.';
  static const int _movementBaseId = 7900;
  static const int _movementMaxNotifications = 3;
  static const String _sunlightChannelId = 'sunlight-coach';
  static const String _sunlightChannelName = 'Rotina de luz natural';
  static const String _sunlightChannelDescription =
      'Lembretes para exposição segura à luz do dia.';
  static const int _sunlightNotificationId = 7915;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  late tz.Location _localLocation;

  Future<LocalNotificationService> init() async {
    if (_initialized) {
      return this;
    }

    tz.initializeTimeZones();
    try {
      final timeZoneName = await DeviceTimezone.getLocalTimezone();
      if (timeZoneName != null && timeZoneName.isNotEmpty) {
        _localLocation = tz.getLocation(timeZoneName);
      } else {
        _localLocation = tz.getLocation('UTC');
      }
    } catch (_) {
      _localLocation = tz.getLocation('UTC');
    }

    tz.setLocalLocation(_localLocation);

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(initializationSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
    return this;
  }

  Future<void> scheduleCheckInReminder(DateTime date) async {
    if (!_initialized) {
      return;
    }

    await cancelCheckInReminder();

    var reminderTime = date.subtract(const Duration(hours: 2));
    if (!reminderTime.isAfter(DateTime.now())) {
      reminderTime = date;
    }

    if (!reminderTime.isAfter(DateTime.now())) {
      return;
    }

    final scheduledDate = _toTzDate(reminderTime);

    try {
      await _plugin.zonedSchedule(
        _checkInNotificationId,
        'Hora de registrar seu peso',
        'Conclua o check-in para liberar o próximo cardápio premium.',
        scheduledDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'nutrition-plan-checkin',
      );
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _checkInNotificationId,
          'Hora de registrar seu peso',
          'Conclua o check-in para liberar o próximo cardápio premium.',
          scheduledDate,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'nutrition-plan-checkin',
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> notifyCheckInAvailable() async {
    if (!_initialized) {
      return;
    }

    await cancelCheckInReminder();
    await _plugin.show(
      _checkInNotificationId,
      'Plano nutricional aguardando check-in',
      'Informe seu peso para liberar a próxima fase do cardápio.',
      _details,
      payload: 'nutrition-plan-checkin',
    );
  }

  Future<void> notifyAppOpened() async {
    if (!_initialized) {
      return;
    }

    await _plugin.show(
      _appOpenNotificationId,
      'Notificações habilitadas',
      'Você abriu o Receitagora e esta é uma notificação de teste.',
      _details,
      payload: 'app-open',
    );
  }

  Future<void> scheduleAppClosedNotificationTest() async {
    if (!_initialized) {
      return;
    }

    await _plugin.cancel(_appClosedNotificationId);

    final scheduledDate =
        tz.TZDateTime.now(_localLocation).add(const Duration(minutes: 1));

    try {
      await _plugin.zonedSchedule(
        _appClosedNotificationId,
        'Teste com o app fechado',
        'Feche o Receitagora e aguarde este lembrete para confirmar as notificações.',
        scheduledDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'app-closed-test',
      );
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _appClosedNotificationId,
          'Teste com o app fechado',
          'Feche o Receitagora e aguarde este lembrete para confirmar as notificações.',
          scheduledDate,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'app-closed-test',
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelAppClosedNotificationTest() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_appClosedNotificationId);
  }

  Future<void> cancelCheckInReminder() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_checkInNotificationId);
  }

  Future<void> scheduleHydrationReminders(HydrationPlanInfo plan) async {
    if (!_initialized) {
      return;
    }

    await cancelHydrationReminders();
    if (!plan.hasReminders) {
      return;
    }

    for (var index = 0; index < plan.reminders.length; index++) {
      final slot = plan.reminders[index];
      final id = _hydrationBaseId + index;
      final tzDate = _nextOccurrence(slot.hour, slot.minute);

      try {
        await _plugin.zonedSchedule(
          id,
          'Hora de se hidratar',
          slot.label,
          tzDate,
          _hydrationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'hydration-${slot.formattedTime}',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } on PlatformException catch (error) {
        if (error.code == 'exact_alarms_not_permitted') {
          await _plugin.zonedSchedule(
            id,
            'Hora de se hidratar',
            slot.label,
            tzDate,
            _hydrationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'hydration-${slot.formattedTime}',
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> cancelHydrationReminders() async {
    if (!_initialized) {
      return;
    }

    for (var index = 0; index < _hydrationMaxNotifications; index++) {
      await _plugin.cancel(_hydrationBaseId + index);
    }
  }

  Future<void> scheduleMindfulBreak({
    required int hour,
    required int minute,
    required String message,
  }) async {
    if (!_initialized) {
      return;
    }

    await cancelMindfulBreak();
    final tzDate = _nextOccurrence(hour, minute);

    try {
      await _plugin.zonedSchedule(
        _mindfulNotificationId,
        'Pausa de bem-estar',
        message,
        tzDate,
        _mindfulDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'mindful-break',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _mindfulNotificationId,
          'Pausa de bem-estar',
          message,
          tzDate,
          _mindfulDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'mindful-break',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelMindfulBreak() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_mindfulNotificationId);
  }

  Future<void> scheduleSleepRoutine({
    required int hour,
    required int minute,
    required String message,
  }) async {
    if (!_initialized) {
      return;
    }

    await cancelSleepRoutine();
    final tzDate = _nextOccurrence(hour, minute);

    try {
      await _plugin.zonedSchedule(
        _sleepNotificationId,
        'Hora de desacelerar',
        message,
        tzDate,
        _sleepDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'sleep-routine',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _sleepNotificationId,
          'Hora de desacelerar',
          message,
          tzDate,
          _sleepDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'sleep-routine',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelSleepRoutine() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_sleepNotificationId);
  }

  Future<void> scheduleWellnessDigest({
    required DateTime digestAt,
    required String title,
    required String message,
  }) async {
    if (!_initialized) {
      return;
    }

    await cancelWellnessDigest();
    final normalized = digestAt.toLocal();
    if (!normalized.isAfter(DateTime.now())) {
      return;
    }
    final target = _toTzDate(normalized);

    try {
      await _plugin.zonedSchedule(
        _digestNotificationId,
        title,
        message,
        target,
        _digestDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'wellness-digest',
      );
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _digestNotificationId,
          title,
          message,
          target,
          _digestDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'wellness-digest',
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelWellnessDigest() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_digestNotificationId);
  }

  Future<void> scheduleMovementBreaks(MovementBreakInfo info) async {
    if (!_initialized) {
      return;
    }

    await cancelMovementBreaks();
    if (!info.hasReminders) {
      return;
    }

    final slots = info.slots.take(_movementMaxNotifications).toList();
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      final id = _movementBaseId + index;
      final tzDate = _nextOccurrence(slot.hour, slot.minute);

      try {
        await _plugin.zonedSchedule(
          id,
          'Pausa ativa',
          slot.activity,
          tzDate,
          _movementDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'movement-${slot.formattedTime}',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } on PlatformException catch (error) {
        if (error.code == 'exact_alarms_not_permitted') {
          await _plugin.zonedSchedule(
            id,
            'Pausa ativa',
            slot.activity,
            tzDate,
            _movementDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'movement-${slot.formattedTime}',
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> cancelMovementBreaks() async {
    if (!_initialized) {
      return;
    }
    for (var index = 0; index < _movementMaxNotifications; index++) {
      await _plugin.cancel(_movementBaseId + index);
    }
  }

  Future<void> scheduleSunlightRoutine(SunlightExposureInfo info) async {
    if (!_initialized) {
      return;
    }

    await cancelSunlightRoutine();
    if (!info.hasReminder) {
      return;
    }

    final tzDate = _nextOccurrence(info.reminderHour, info.reminderMinute);

    try {
      await _plugin.zonedSchedule(
        _sunlightNotificationId,
        'Luz natural do dia',
        info.message,
        tzDate,
        _sunlightDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'sunlight-routine',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _sunlightNotificationId,
          'Luz natural do dia',
          info.message,
          tzDate,
          _sunlightDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'sunlight-routine',
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelSunlightRoutine() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_sunlightNotificationId);
  }

  NotificationDetails get _details {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails get _hydrationDetails {
    const androidDetails = AndroidNotificationDetails(
      _hydrationChannelId,
      _hydrationChannelName,
      channelDescription: _hydrationChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails get _mindfulDetails {
    const androidDetails = AndroidNotificationDetails(
      _mindfulChannelId,
      _mindfulChannelName,
      channelDescription: _mindfulChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails get _sleepDetails {
    const androidDetails = AndroidNotificationDetails(
      _sleepChannelId,
      _sleepChannelName,
      channelDescription: _sleepChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails get _digestDetails {
    const androidDetails = AndroidNotificationDetails(
      _digestChannelId,
      _digestChannelName,
      channelDescription: _digestChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails get _movementDetails {
    const androidDetails = AndroidNotificationDetails(
      _movementChannelId,
      _movementChannelName,
      channelDescription: _movementChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails get _sunlightDetails {
    const androidDetails = AndroidNotificationDetails(
      _sunlightChannelId,
      _sunlightChannelName,
      channelDescription: _sunlightChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(_localLocation);
    var scheduled = tz.TZDateTime(
      _localLocation,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _toTzDate(DateTime date) {
    final local = date.toLocal();
    return tz.TZDateTime(
      _localLocation,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );
  }
}
