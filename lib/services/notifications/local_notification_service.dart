import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService extends GetxService {
  LocalNotificationService();

  static const String _channelId = 'nutrition-plan-reminders';
  static const String _channelName = 'Lembretes do plano nutricional';
  static const String _channelDescription =
      'Alertas para check-ins e atualizações do plano premium.';
  static const int _checkInNotificationId = 7812;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<LocalNotificationService> init() async {
    if (_initialized) {
      return this;
    }

    tz.initializeTimeZones();

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

    final scheduledDate = tz.TZDateTime.from(reminderTime.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      _checkInNotificationId,
      'Hora de registrar seu peso',
      'Conclua o check-in para liberar o próximo cardápio premium.',
      scheduledDate,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'nutrition-plan-checkin',
    );
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

  Future<void> cancelCheckInReminder() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(_checkInNotificationId);
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
}
