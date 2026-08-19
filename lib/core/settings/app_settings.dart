/// Visual quality tier. See 04-ui-ux-and-visual-system.md.
///
/// `auto` currently resolves to [standard] until device-capability profiling
/// is implemented (a later phase); it is kept as a distinct, persisted
/// choice now so the setting's storage format does not need to migrate.
enum VisualQuality { auto, low, standard, high }

/// Reduced-motion preference. `system` follows the OS accessibility setting.
enum ReducedMotionPreference { system, on, off }

/// Immutable, persisted app-wide settings.
///
/// Defaults match 06-localization-social-and-settings.md: sound on, haptics
/// on, language follows device on first run (falling back to English when
/// the device language isn't supported), Standard visual quality, timer
/// off, reduced motion follows system, high contrast off.
class AppSettings {
  final String languageCode; // 'en' or 'ur'
  final bool soundOn;
  final bool hapticsOn;
  final ReducedMotionPreference reducedMotion;
  final bool highContrast;
  final VisualQuality visualQuality;

  /// Default total-time-per-player timer, in minutes. 0 means off.
  final int timerDefaultMinutes;

  const AppSettings({
    required this.languageCode,
    required this.soundOn,
    required this.hapticsOn,
    required this.reducedMotion,
    required this.highContrast,
    required this.visualQuality,
    required this.timerDefaultMinutes,
  });

  static const supportedLanguageCodes = <String>{'en', 'ur'};

  factory AppSettings.defaults({required String deviceLanguageCode}) {
    final language = supportedLanguageCodes.contains(deviceLanguageCode)
        ? deviceLanguageCode
        : 'en';
    return AppSettings(
      languageCode: language,
      soundOn: true,
      hapticsOn: true,
      reducedMotion: ReducedMotionPreference.system,
      highContrast: false,
      visualQuality: VisualQuality.standard,
      timerDefaultMinutes: 0,
    );
  }

  AppSettings copyWith({
    String? languageCode,
    bool? soundOn,
    bool? hapticsOn,
    ReducedMotionPreference? reducedMotion,
    bool? highContrast,
    VisualQuality? visualQuality,
    int? timerDefaultMinutes,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      soundOn: soundOn ?? this.soundOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      visualQuality: visualQuality ?? this.visualQuality,
      timerDefaultMinutes: timerDefaultMinutes ?? this.timerDefaultMinutes,
    );
  }

  Map<String, Object?> toJson() => {
    'languageCode': languageCode,
    'soundOn': soundOn,
    'hapticsOn': hapticsOn,
    'reducedMotion': reducedMotion.name,
    'highContrast': highContrast,
    'visualQuality': visualQuality.name,
    'timerDefaultMinutes': timerDefaultMinutes,
  };

  factory AppSettings.fromJson(
    Map<String, Object?> json, {
    required String deviceLanguageCode,
  }) {
    final fallback = AppSettings.defaults(
      deviceLanguageCode: deviceLanguageCode,
    );
    final languageCode = json['languageCode'] as String?;
    return AppSettings(
      languageCode: AppSettings.supportedLanguageCodes.contains(languageCode)
          ? languageCode!
          : fallback.languageCode,
      soundOn: json['soundOn'] as bool? ?? fallback.soundOn,
      hapticsOn: json['hapticsOn'] as bool? ?? fallback.hapticsOn,
      reducedMotion: ReducedMotionPreference.values.firstWhere(
        (value) => value.name == json['reducedMotion'],
        orElse: () => fallback.reducedMotion,
      ),
      highContrast: json['highContrast'] as bool? ?? fallback.highContrast,
      visualQuality: VisualQuality.values.firstWhere(
        (value) => value.name == json['visualQuality'],
        orElse: () => fallback.visualQuality,
      ),
      timerDefaultMinutes:
          json['timerDefaultMinutes'] as int? ?? fallback.timerDefaultMinutes,
    );
  }
}
