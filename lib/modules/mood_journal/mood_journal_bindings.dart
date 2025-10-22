import 'package:get/get.dart';

import 'package:receitagora/services/wellness/mood_journal_service.dart';

import 'mood_journal_controller.dart';

class MoodJournalBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MoodJournalController>(() => MoodJournalController(
          journalService: Get.find<MoodJournalService>(),
        ));
  }
}
