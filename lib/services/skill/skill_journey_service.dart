import 'package:receitagora/models/skill/skill_journey.dart';

abstract class SkillJourneyService {
  List<SkillJourney> get journeys;
  SkillJourney? findById(String id);
}
