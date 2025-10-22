import 'package:get/get.dart';

import 'package:receitagora/services/skill/skill_journey_service.dart';

import 'skill_journey_detail_controller.dart';
import 'skill_journeys_controller.dart';

class SkillJourneysBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SkillJourneysController>()) {
      Get.lazyPut<SkillJourneysController>(() => SkillJourneysController(
            journeyService: Get.find<SkillJourneyService>(),
          ));
    }
  }
}

class SkillJourneyDetailBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SkillJourneyDetailController>(() => SkillJourneyDetailController(
          journeyService: Get.find<SkillJourneyService>(),
        ));
  }
}
