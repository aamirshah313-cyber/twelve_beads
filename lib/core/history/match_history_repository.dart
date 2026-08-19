import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'match_record.dart';

/// Local, versioned persistence for the default profile's match history.
/// Individual corrupted/malformed entries are skipped rather than
/// discarding the whole history, and the list is capped so it can't grow
/// without bound on a long-lived install.
class MatchHistoryRepository {
  MatchHistoryRepository(this._prefs);

  static const _storageKey = 'match_history.default.v1';
  static const maxEntries = 200;

  final SharedPreferences _prefs;

  static Future<MatchHistoryRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MatchHistoryRepository(prefs);
  }

  List<MatchRecord> load() {
    final raw = _prefs.getStringList(_storageKey);
    if (raw == null) return const [];
    final records = <MatchRecord>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, Object?>) {
          records.add(MatchRecord.fromJson(decoded));
        }
      } catch (_) {
        // Skip a single corrupted/malformed entry rather than losing the
        // rest of the history.
      }
    }
    return records;
  }

  Future<void> save(List<MatchRecord> records) {
    final capped = records.length > maxEntries
        ? records.sublist(records.length - maxEntries)
        : records;
    return _prefs.setStringList(_storageKey, [
      for (final record in capped) jsonEncode(record.toJson()),
    ]);
  }

  Future<void> deleteAll() => _prefs.remove(_storageKey);
}
