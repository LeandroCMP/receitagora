import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'skill_journey_detail_page.dart';
import 'skill_journeys_bindings.dart';
import 'skill_journeys_page.dart';

class SkillJourneysModule extends Module {
  @override
  List<GetPage<dynamic>> get routers => <GetPage<dynamic>>[
        GetPage<dynamic>(
          name: AppRoutes.skillJourneys,
          page: () => const SkillJourneysPage(),
          binding: SkillJourneysBindings(),
        ),
        GetPage<dynamic>(
          name: AppRoutes.skillJourneyDetail,
          page: () => const SkillJourneyDetailPage(),
          binding: SkillJourneyDetailBindings(),
        ),
      ];
}
