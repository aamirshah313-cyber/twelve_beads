import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Local, versioned persistence for [AppSettings] backed by
/// [SharedPreferences]. Malformed or corrupted stored data is discarded and
/// recovered to defaults rather than crashing the app.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _storageKey = 'settings.v1';

  final SharedPreferences _prefs;

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  AppSettings load({required String deviceLanguageCode}) {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      return AppSettings.defaults(deviceLanguageCode: deviceLanguageCode);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return AppSettings.defaults(deviceLanguageCode: deviceLanguageCode);
      }
      return AppSettings.fromJson(
        decoded,
        deviceLanguageCode: deviceLanguageCode,
      );
    } on FormatException {
      return AppSettings.defaults(deviceLanguageCode: deviceLanguageCode);
    }
  }

  Future<void> save(AppSettings settings) {
    return _prefs.setString(_storageKey, jsonEncode(settings.toJson()));
  }

  /// Removes all locally stored settings. Part of the required
  /// "delete local data" privacy control.
  Future<void> deleteAll() {
    return _prefs.remove(_storageKey);
  }
}
