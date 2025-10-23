import 'dart:async';

import 'package:get/get.dart';

import 'package:receitagora/models/wellness/mood_entry.dart';
import 'package:receitagora/services/wellness/mood_journal_service.dart';

class MoodJournalController extends GetxController {
  MoodJournalController({required this.journalService});

  final MoodJournalService journalService;

  final RxList<MoodEntry> entries = <MoodEntry>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<MoodEntry>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    await journalService.ensureInitialized();
    entries.assignAll(journalService.entries);
    _subscription = journalService.entriesStream.listen((items) {
      entries.assignAll(items);
    });
    isLoading.value = false;
  }

  Future<void> saveEntry({
    String? id,
    required DateTime date,
    required MoodLevel mood,
    String? note,
  }) async {
    final sanitized = note?.trim();
    final normalizedNote = sanitized?.isEmpty == true ? null : sanitized;
    if (id == null) {
      await journalService.addEntry(
        date: date,
        mood: mood,
        note: normalizedNote,
      );
    } else {
      await journalService.updateEntry(
        MoodEntry(
          id: id,
          date: date,
          mood: mood,
          note: normalizedNote,
        ),
      );
    }
  }

  Future<void> deleteEntry(String id) {
    return journalService.deleteEntry(id);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
