import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receitagora/models/wellness/mood_entry.dart';

import 'mood_journal_service.dart';

class MoodJournalServiceImpl extends GetxService implements MoodJournalService {
  MoodJournalServiceImpl({required SharedPreferences preferences})
      : _preferences = preferences;

  final SharedPreferences _preferences;

  static const String _storageKey = 'wellness.moodJournal.entries';

  final RxList<MoodEntry> _entries = <MoodEntry>[].obs;
  bool _initialized = false;
  final Completer<void> _initializing = Completer<void>();

  @override
  List<MoodEntry> get entries => List.unmodifiable(_entries);

  @override
  Stream<List<MoodEntry>> get entriesStream => _entries.stream;

  @override
  Future<void> ensureInitialized() async {
    if (_initialized) {
      return _initializing.future;
    }

    try {
      if (!_initializing.isCompleted) {
        final raw = _preferences.getString(_storageKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            final parsed = decoded
                .map((item) => item is Map<String, dynamic>
                    ? MoodEntry.fromJson(item)
                    : item is Map
                        ? MoodEntry.fromJson(Map<String, dynamic>.from(item))
                        : null)
                .whereType<MoodEntry>()
                .toList();
            parsed.sort((a, b) => b.date.compareTo(a.date));
            _entries.assignAll(parsed);
          }
        }
        _initializing.complete();
        _initialized = true;
      }
    } catch (error) {
      if (!_initializing.isCompleted) {
        _initializing.completeError(error);
      }
      rethrow;
    }

    return _initializing.future;
  }

  @override
  Future<MoodEntry> addEntry({
    required DateTime date,
    required MoodLevel mood,
    String? note,
  }) async {
    await ensureInitialized();

    final normalizedDate = _normalize(date);
    final sanitizedNote = note?.trim();
    final existingIndex = _entries.indexWhere(
      (entry) => _isSameDay(entry.date, normalizedDate),
    );

    final entry = MoodEntry(
      id: existingIndex >= 0
          ? _entries[existingIndex].id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      date: normalizedDate,
      mood: mood,
      note: sanitizedNote?.isEmpty == true ? null : sanitizedNote,
    );

    if (existingIndex >= 0) {
      _entries[existingIndex] = entry;
    } else {
      _entries.add(entry);
    }
    _sortEntries();
    await _persist();
    return entry;
  }

  @override
  Future<MoodEntry> updateEntry(MoodEntry entry) async {
    await ensureInitialized();

    final normalized = entry.copyWith(date: _normalize(entry.date));
    final index = _entries.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      _entries[index] = normalized;
    } else {
      _entries.add(normalized);
    }
    _sortEntries();
    await _persist();
    return normalized;
  }

  @override
  Future<void> deleteEntry(String id) async {
    await ensureInitialized();
    _entries.removeWhere((entry) => entry.id == id);
    await _persist();
  }

  void _sortEntries() {
    _entries.sort((a, b) => b.date.compareTo(a.date));
    _entries.refresh();
  }

  Future<void> _persist() async {
    final payload = _entries.map((entry) => entry.toJson()).toList();
    await _preferences.setString(_storageKey, jsonEncode(payload));
  }

  DateTime _normalize(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
