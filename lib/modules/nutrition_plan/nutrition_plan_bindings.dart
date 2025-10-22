import 'package:get/get.dart';

import 'package:receitagora/services/nutrition/nutrition_plan_service.dart';
import 'package:receitagora/services/notifications/local_notification_service.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'nutrition_plan_controller.dart';

class NutritionPlanBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NutritionPlanController>(
      () => NutritionPlanController(
        service: Get.find<NutritionPlanService>(),
        sessionService: Get.find<SessionService>(),
        notificationService: Get.find<LocalNotificationService>(),
      ),
    );
  }
}
