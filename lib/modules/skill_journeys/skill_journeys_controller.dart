import 'package:get/get.dart';

import 'package:receitagora/application/routes/app_routes.dart';
import 'package:receitagora/models/skill/skill_journey.dart';
import 'package:receitagora/services/skill/skill_journey_service.dart';

class SkillJourneysController extends GetxController {
  SkillJourneysController({required this.journeyService});

  final SkillJourneyService journeyService;

  final RxList<SkillJourney> journeys = <SkillJourney>[].obs;

  @override
  void onInit() {
    super.onInit();
    journeys.assignAll(journeyService.journeys);
  }

  void openJourney(SkillJourney journey) {
    Get.toNamed(
      AppRoutes.skillJourneyDetail,
      arguments: <String, String>{'journeyId': journey.id},
    );
  }
}
