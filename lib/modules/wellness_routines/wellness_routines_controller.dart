import 'dart:async';

import 'package:get/get.dart';

import 'package:receitagora/services/wellness/wellness_routine_service.dart';

class WellnessRoutinesController extends GetxController {
  WellnessRoutinesController({required this.service});

  final WellnessRoutineService service;

  final RxList<WellnessRoutine> routines = <WellnessRoutine>[].obs;
  final RxSet<String> enabled = <String>{}.obs;

  StreamSubscription<Set<String>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    routines.assignAll(service.routines);
    enabled.assignAll(service.enabledRoutines);
    _subscription = service.enabledRoutinesStream.listen(enabled.assignAll);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> toggleRoutine(WellnessRoutine routine, bool enable) async {
    await service.toggleRoutine(routine.id, enable);
  }
}
