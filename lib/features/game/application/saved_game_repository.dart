import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'saved_game.dart';

/// Local, versioned persistence for a single resumable in-progress match.
/// Only one saved game exists at a time — starting or resuming a match
/// replaces or clears it. Malformed/corrupted stored data is discarded
/// (treated as "no saved game") rather than crashing the app.
class SavedGameRepository {
  SavedGameRepository(this._prefs);

  static const _storageKey = 'saved_game.default.v1';

  final SharedPreferences _prefs;

  static Future<SavedGameRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SavedGameRepository(prefs);
  }

  SavedGameSnapshot? load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return SavedGameSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SavedGameSnapshot snapshot) {
    return _prefs.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() => _prefs.remove(_storageKey);
}
