import 'dart:async';

class WellnessRoutineAction {
  const WellnessRoutineAction({
    required this.type,
    required this.data,
  });

  final WellnessRoutineActionType type;
  final Object data;
}

enum WellnessRoutineActionType {
  hydration,
  mindfulBreak,
  sleep,
  movement,
  sunlight,
}

class WellnessRoutine {
  const WellnessRoutine({
    required this.id,
    required this.title,
    required this.description,
    required this.highlights,
    required this.actions,
  });

  final String id;
  final String title;
  final String description;
  final List<String> highlights;
  final List<WellnessRoutineAction> actions;
}

abstract class WellnessRoutineService {
  List<WellnessRoutine> get routines;
  Set<String> get enabledRoutines;
  Stream<Set<String>> get enabledRoutinesStream;

  Future<void> toggleRoutine(String routineId, bool enable);
}
