import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/services/notifications/local_notification_service.dart';

import 'wellness_routine_service.dart';

class WellnessRoutineServiceImpl extends GetxService
    implements WellnessRoutineService {
  WellnessRoutineServiceImpl({
    required SharedPreferences preferences,
    required LocalNotificationService notificationService,
  })  : _preferences = preferences,
        _notificationService = notificationService {
    _hydrate();
  }

  final SharedPreferences _preferences;
  final LocalNotificationService _notificationService;

  static const String _storageKey = 'wellness.routines.enabled';

  final RxSet<String> _enabled = <String>{}.obs;

  @override
  List<WellnessRoutine> get routines => List<WellnessRoutine>.unmodifiable(_routines);

  @override
  Set<String> get enabledRoutines => Set<String>.unmodifiable(_enabled);

  @override
  Stream<Set<String>> get enabledRoutinesStream => _enabled.stream;

  @override
  Future<void> toggleRoutine(String routineId, bool enable) async {
    final exists = _routines.any((routine) => routine.id == routineId);
    if (!exists) {
      return;
    }

    final updated = Set<String>.from(_enabled);
    if (enable) {
      updated.add(routineId);
    } else {
      updated.remove(routineId);
    }

    _enabled.assignAll(updated);
    await _persist();
    await _applyConfiguration();
  }

  Future<void> _persist() async {
    await _preferences.setString(_storageKey, jsonEncode(_enabled.toList()));
  }

  void _hydrate() {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _enabled.clear();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Iterable) {
        final values = decoded.map((dynamic item) => item.toString()).toSet();
        _enabled.assignAll(values);
      }
    } catch (error, stackTrace) {
      Get.log(
        'Falha ao carregar rotinas de bem-estar: $error\n$stackTrace',
        isError: true,
      );
      _enabled.clear();
    }
  }

  Future<void> _applyConfiguration() async {
    final enabled = Set<String>.from(_enabled);

    final HydrationPlanInfo? hydrationPlan = _selectActionData<HydrationPlanInfo>(
      enabled,
      WellnessRoutineActionType.hydration,
    );
    final _MindfulPayload? mindfulPayload =
        _selectActionData<_MindfulPayload>(enabled, WellnessRoutineActionType.mindfulBreak);
    final SleepRoutineInfo? sleepInfo = _selectActionData<SleepRoutineInfo>(
      enabled,
      WellnessRoutineActionType.sleep,
    );
    final MovementBreakInfo? movementInfo = _selectActionData<MovementBreakInfo>(
      enabled,
      WellnessRoutineActionType.movement,
    );
    final SunlightExposureInfo? sunlightInfo = _selectActionData<SunlightExposureInfo>(
      enabled,
      WellnessRoutineActionType.sunlight,
    );

    if (hydrationPlan == null || !hydrationPlan.hasReminders) {
      await _notificationService.cancelHydrationReminders();
    } else {
      await _notificationService.scheduleHydrationReminders(hydrationPlan);
    }

    if (mindfulPayload == null) {
      await _notificationService.cancelMindfulBreak();
    } else {
      await _notificationService.scheduleMindfulBreak(
        hour: mindfulPayload.hour,
        minute: mindfulPayload.minute,
        message: mindfulPayload.message,
      );
    }

    if (sleepInfo == null || !sleepInfo.hasReminder) {
      await _notificationService.cancelSleepRoutine();
    } else {
      await _notificationService.scheduleSleepRoutine(
        hour: sleepInfo.reminderHour,
        minute: sleepInfo.reminderMinute,
        message: sleepInfo.message,
      );
    }

    if (movementInfo == null || !movementInfo.hasReminders) {
      await _notificationService.cancelMovementBreaks();
    } else {
      await _notificationService.scheduleMovementBreaks(movementInfo);
    }

    if (sunlightInfo == null || !sunlightInfo.hasReminder) {
      await _notificationService.cancelSunlightRoutine();
    } else {
      await _notificationService.scheduleSunlightRoutine(sunlightInfo);
    }
  }

  T? _selectActionData<T>(Set<String> enabled, WellnessRoutineActionType type) {
    for (final routine in _routines) {
      if (!enabled.contains(routine.id)) {
        continue;
      }
      for (final action in routine.actions) {
        if (action.type == type && action.data is T) {
          return action.data as T;
        }
      }
    }
    return null;
  }

  List<WellnessRoutine> get _routines => _cachedRoutines ??= _buildRoutines();
  List<WellnessRoutine>? _cachedRoutines;

  List<WellnessRoutine> _buildRoutines() {
    return <WellnessRoutine>[
      WellnessRoutine(
        id: 'essential_balance',
        title: 'Essenciais do dia',
        description:
            'Hidratação distribuída, pausa mindful à tarde e lembrete rápido de luz natural para manter energia estável.',
        highlights: const <String>[
          'Quatro lembretes de água com frases motivacionais;',
          'Pausa consciente às 15h para aliviar tensões;',
          'Lembrete suave para sair ao sol pela manhã.',
        ],
        actions: <WellnessRoutineAction>[
          WellnessRoutineAction(
            type: WellnessRoutineActionType.hydration,
            data: HydrationPlanInfo(
              totalMl: 2200,
              tip: 'Distribua goles ao longo do dia e mantenha uma garrafa por perto.',
              reminders: const <HydrationReminderSlot>[
                HydrationReminderSlot(
                  hour: 9,
                  minute: 0,
                  amountMl: 300,
                  label: '09:00 - Copo para despertar o corpo',
                ),
                HydrationReminderSlot(
                  hour: 11,
                  minute: 30,
                  amountMl: 300,
                  label: '11:30 - Água antes do almoço',
                ),
                HydrationReminderSlot(
                  hour: 14,
                  minute: 30,
                  amountMl: 300,
                  label: '14:30 - Pausa rápida para hidratação',
                ),
                HydrationReminderSlot(
                  hour: 17,
                  minute: 30,
                  amountMl: 300,
                  label: '17:30 - Último copo antes do fim do expediente',
                ),
              ],
            ),
          ),
          WellnessRoutineAction(
            type: WellnessRoutineActionType.mindfulBreak,
            data: const _MindfulPayload(
              hour: 15,
              minute: 30,
              message: 'Levante, respire fundo e alongue ombros por 3 minutos.',
            ),
          ),
          WellnessRoutineAction(
            type: WellnessRoutineActionType.sunlight,
            data: const SunlightExposureInfo(
              enabled: true,
              reminderHour: 9,
              reminderMinute: 30,
              durationMinutes: 10,
              message: 'Abra a janela ou dê uma volta ao ar livre para acordar o corpo.',
              benefits: <String>[],
              cautions: <String>[],
            ),
          ),
        ],
      ),
      WellnessRoutine(
        id: 'focused_flow',
        title: 'Foco produtivo',
        description:
            'Combina uma pausa guiada e dois lembretes de movimento para manter concentração e evitar tensão muscular.',
        highlights: const <String>[
          'Pausa mindful curta após o almoço;',
          'Dois alertas de alongamento com sugestões rápidas;',
          'Equilíbrio entre foco e descanso ativo.',
        ],
        actions: <WellnessRoutineAction>[
          WellnessRoutineAction(
            type: WellnessRoutineActionType.mindfulBreak,
            data: const _MindfulPayload(
              hour: 13,
              minute: 45,
              message: 'Respire fundo, solte o maxilar e volte com energia.',
            ),
          ),
          WellnessRoutineAction(
            type: WellnessRoutineActionType.movement,
            data: const MovementBreakInfo(
              enabled: true,
              summary: 'Alongamentos leves para reativar a circulação.',
              slots: <MovementBreakSlot>[
                MovementBreakSlot(
                  hour: 11,
                  minute: 0,
                  durationMinutes: 3,
                  activity: 'Estique braços e coluna por 2 minutos.',
                ),
                MovementBreakSlot(
                  hour: 16,
                  minute: 0,
                  durationMinutes: 3,
                  activity: 'Caminhe pela casa e role os ombros lentamente.',
                ),
              ],
              tips: <String>[],
            ),
          ),
        ],
      ),
      WellnessRoutine(
        id: 'restful_evening',
        title: 'Noite restauradora',
        description:
            'Ajuda a desacelerar no fim do dia com lembrete de sono e sugestão de preparo para uma noite tranquila.',
        highlights: const <String>[
          'Aviso às 21h30 para diminuir luzes e telas;',
          'Sugestões curtas de relaxamento e respiração;',
          'Mantém rotina consistente para dormir melhor.',
        ],
        actions: <WellnessRoutineAction>[
          WellnessRoutineAction(
            type: WellnessRoutineActionType.sleep,
            data: const SleepRoutineInfo(
              enabled: true,
              reminderHour: 21,
              reminderMinute: 30,
              message: 'Desacelere: reduza telas, alongue e prepare o ambiente para o sono.',
              windDownSummary: '',
              windDownTips: <String>[],
            ),
          ),
        ],
      ),
    ];
  }
}

class _MindfulPayload {
  const _MindfulPayload({
    required this.hour,
    required this.minute,
    required this.message,
  });

  final int hour;
  final int minute;
  final String message;
}
