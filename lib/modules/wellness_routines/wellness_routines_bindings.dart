import 'package:get/get.dart';

import 'package:receitagora/services/wellness/wellness_routine_service.dart';

import 'wellness_routines_controller.dart';

class WellnessRoutinesBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WellnessRoutinesController>(
      () => WellnessRoutinesController(
        service: Get.find<WellnessRoutineService>(),
      ),
    );
  }
}
