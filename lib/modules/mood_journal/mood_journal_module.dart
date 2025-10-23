import 'package:get/get.dart';

import 'package:receitagora/application/modules/module.dart';
import 'package:receitagora/application/routes/app_routes.dart';

import 'mood_journal_bindings.dart';
import 'mood_journal_page.dart';

class MoodJournalModule extends Module {
  @override
  List<GetPage<dynamic>> get routers => <GetPage<dynamic>>[
        GetPage<dynamic>(
          name: AppRoutes.moodJournal,
          page: () => const MoodJournalPage(),
          binding: MoodJournalBindings(),
        ),
      ];
}
