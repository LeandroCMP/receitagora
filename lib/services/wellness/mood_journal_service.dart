import 'dart:async';

import 'package:receitagora/models/wellness/mood_entry.dart';

abstract class MoodJournalService {
  Future<void> ensureInitialized();

  List<MoodEntry> get entries;
  Stream<List<MoodEntry>> get entriesStream;

  Future<MoodEntry> addEntry({
    required DateTime date,
    required MoodLevel mood,
    String? note,
  });

  Future<MoodEntry> updateEntry(MoodEntry entry);

  Future<void> deleteEntry(String id);
}
