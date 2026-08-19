import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'profile_stats.dart';

/// Local, versioned persistence for the default local [ProfileStats].
/// Malformed or corrupted stored data is discarded and recovered to a fresh
/// default profile rather than crashing the app.
class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _storageKey = 'profile.default.v1';

  final SharedPreferences _prefs;

  static Future<ProfileRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfileRepository(prefs);
  }

  ProfileStats load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      return ProfileStats.defaultProfile();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return ProfileStats.defaultProfile();
      }
      return ProfileStats.fromJson(decoded);
    } on FormatException {
      return ProfileStats.defaultProfile();
    }
  }

  Future<void> save(ProfileStats stats) {
    return _prefs.setString(_storageKey, jsonEncode(stats.toJson()));
  }

  Future<void> deleteAll() {
    return _prefs.remove(_storageKey);
  }
}
