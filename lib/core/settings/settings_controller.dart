import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';
import 'settings_repository.dart';

/// Overridden in `main.dart` once the repository has been created
/// asynchronously, before the app is run.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden in main()',
  );
});

/// Overridden in `main.dart` with the platform's reported locale language
/// code, so first-run language selection can follow the device.
final deviceLanguageCodeProvider = Provider<String>((ref) => 'en');

/// Holds the current [AppSettings] and persists every change immediately,
/// per the "Changes must preview where reasonable and persist immediately"
/// requirement.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repository = ref.read(settingsRepositoryProvider);
    final deviceLanguageCode = ref.read(deviceLanguageCodeProvider);
    return repository.load(deviceLanguageCode: deviceLanguageCode);
  }

  void _update(AppSettings Function(AppSettings current) updater) {
    state = updater(state);
    ref.read(settingsRepositoryProvider).save(state);
  }

  void setLanguageCode(String languageCode) =>
      _update((s) => s.copyWith(languageCode: languageCode));

  void setSoundOn(bool value) => _update((s) => s.copyWith(soundOn: value));

  void setHapticsOn(bool value) => _update((s) => s.copyWith(hapticsOn: value));

  void setReducedMotion(ReducedMotionPreference value) =>
      _update((s) => s.copyWith(reducedMotion: value));

  void setHighContrast(bool value) =>
      _update((s) => s.copyWith(highContrast: value));

  void setVisualQuality(VisualQuality value) =>
      _update((s) => s.copyWith(visualQuality: value));

  void setTimerDefaultMinutes(int value) =>
      _update((s) => s.copyWith(timerDefaultMinutes: value));

  /// Resets settings to defaults and clears persisted storage, as part of
  /// the required local-data-deletion control.
  Future<void> deleteAllAndReset({required String deviceLanguageCode}) async {
    await ref.read(settingsRepositoryProvider).deleteAll();
    state = AppSettings.defaults(deviceLanguageCode: deviceLanguageCode);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
