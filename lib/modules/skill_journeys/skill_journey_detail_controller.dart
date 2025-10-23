import 'package:get/get.dart';

import 'package:receitagora/models/skill/skill_journey.dart';
import 'package:receitagora/services/skill/skill_journey_service.dart';

class SkillJourneyDetailController extends GetxController {
  SkillJourneyDetailController({required this.journeyService});

  final SkillJourneyService journeyService;

  final Rxn<SkillJourney> journey = Rxn<SkillJourney>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    String? id;
    if (args is Map && args['journeyId'] is String) {
      id = args['journeyId'] as String;
    }
    if (id == null && Get.parameters.containsKey('journeyId')) {
      id = Get.parameters['journeyId'];
    }

    if (id != null) {
      journey.value = journeyService.findById(id);
    }
  }
}
