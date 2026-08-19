import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// Application name shown in the OS and app bar.
  ///
  /// In en, this message translates to:
  /// **'Twelve Beads'**
  String get appTitle;

  /// No description provided for @navPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// No description provided for @navHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get navHowToPlay;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Shown on the home screen so the active language is always visible.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String homeCurrentLanguage(String language);

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// No description provided for @languageNameUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageNameUrdu;

  /// No description provided for @gameScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get gameScreenTitle;

  /// No description provided for @gameModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get gameModeLabel;

  /// No description provided for @gameModeTwoPlayer.
  ///
  /// In en, this message translates to:
  /// **'Two Players'**
  String get gameModeTwoPlayer;

  /// No description provided for @gameModeVsMachine.
  ///
  /// In en, this message translates to:
  /// **'Vs Machine'**
  String get gameModeVsMachine;

  /// No description provided for @playerOneNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Player 1 name'**
  String get playerOneNameLabel;

  /// No description provided for @playerTwoNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Player 2 name'**
  String get playerTwoNameLabel;

  /// No description provided for @firstTurnLabel.
  ///
  /// In en, this message translates to:
  /// **'First turn'**
  String get firstTurnLabel;

  /// No description provided for @firstTurnRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get firstTurnRandom;

  /// No description provided for @firstTurnPlayerOne.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get firstTurnPlayerOne;

  /// No description provided for @firstTurnPlayerTwo.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get firstTurnPlayerTwo;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyDifficult.
  ///
  /// In en, this message translates to:
  /// **'Difficult'**
  String get difficultyDifficult;

  /// No description provided for @timerLabel.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerLabel;

  /// No description provided for @timerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get timerOff;

  /// No description provided for @startMatchButton.
  ///
  /// In en, this message translates to:
  /// **'Start Match'**
  String get startMatchButton;

  /// No description provided for @engineNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'The match engine isn\'t built yet — that\'s a later phase. Your setup has been saved.'**
  String get engineNotReadyMessage;

  /// No description provided for @rulesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get rulesScreenTitle;

  /// No description provided for @rulesBoardHeading.
  ///
  /// In en, this message translates to:
  /// **'The Board'**
  String get rulesBoardHeading;

  /// No description provided for @rulesBoardBody.
  ///
  /// In en, this message translates to:
  /// **'The board has 25 junctions arranged in a 5×5 grid. Every junction is connected to its horizontal and vertical neighbors, and every one of the 16 small squares also has both diagonal lines drawn — so most junctions connect in up to 8 directions. Each side starts with 12 beads: two full rows closest to that side, plus the two middle-row junctions nearest to it. Only the very center junction starts empty.'**
  String get rulesBoardBody;

  /// No description provided for @rulesMovementHeading.
  ///
  /// In en, this message translates to:
  /// **'Movement & Captures'**
  String get rulesMovementHeading;

  /// No description provided for @rulesMovementBody.
  ///
  /// In en, this message translates to:
  /// **'A bead moves one step along any connected line, in any direction, to an empty junction. A capture jumps in a straight line over an adjacent opponent bead onto an empty junction directly beyond it, removing the jumped bead. If any capture is available, you must capture rather than make a simple move. If that capture lands somewhere with another capture available, you must continue jumping until no more captures remain from that spot.'**
  String get rulesMovementBody;

  /// No description provided for @rulesWinningHeading.
  ///
  /// In en, this message translates to:
  /// **'Winning'**
  String get rulesWinningHeading;

  /// No description provided for @rulesWinningBody.
  ///
  /// In en, this message translates to:
  /// **'You win by capturing every one of your opponent\'s beads, or by leaving them with no legal move on their turn. A match with no capture for 40 turns in a row ends in a draw.'**
  String get rulesWinningBody;

  /// No description provided for @rulesVariantLabel.
  ///
  /// In en, this message translates to:
  /// **'Ruleset: Classic'**
  String get rulesVariantLabel;

  /// No description provided for @rulesOpenQuestionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Defaults, open to change'**
  String get rulesOpenQuestionsHeading;

  /// No description provided for @rulesOpenQuestionsBody.
  ///
  /// In en, this message translates to:
  /// **'These rules use sensible defaults for this style of board rather than a confirmed regional source: no maximum-capture requirement (any legal capture is enough), and a 40-turn no-capture limit as a safeguard rather than a traditional repetition rule. Ask to change these any time.'**
  String get rulesOpenQuestionsBody;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get profileDefaultName;

  /// No description provided for @profileStatsMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get profileStatsMatches;

  /// No description provided for @profileStatsWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get profileStatsWins;

  /// No description provided for @profileStatsLosses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get profileStatsLosses;

  /// No description provided for @profileStatsDraws.
  ///
  /// In en, this message translates to:
  /// **'Draws'**
  String get profileStatsDraws;

  /// No description provided for @profileStatsStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get profileStatsStreak;

  /// No description provided for @profileStatsCaptures.
  ///
  /// In en, this message translates to:
  /// **'Captures'**
  String get profileStatsCaptures;

  /// No description provided for @profileBadgesHeading.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadgesHeading;

  /// No description provided for @profileNoBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges earned yet'**
  String get profileNoBadgesYet;

  /// No description provided for @profileNoMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches played yet'**
  String get profileNoMatchesYet;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSoundLabel;

  /// No description provided for @settingsHapticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHapticsLabel;

  /// No description provided for @settingsReducedMotionLabel.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get settingsReducedMotionLabel;

  /// No description provided for @reducedMotionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get reducedMotionSystem;

  /// No description provided for @settingsHighContrastLabel.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get settingsHighContrastLabel;

  /// No description provided for @settingsVisualQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visual quality'**
  String get settingsVisualQualityLabel;

  /// No description provided for @visualQualityAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get visualQualityAuto;

  /// No description provided for @visualQualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get visualQualityLow;

  /// No description provided for @visualQualityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get visualQualityStandard;

  /// No description provided for @visualQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get visualQualityHigh;

  /// No description provided for @settingsTimerDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default timer'**
  String get settingsTimerDefaultLabel;

  /// No description provided for @settingsPrivacyHeading.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyHeading;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All profiles, match history and quick chat stay on this device. Twelve Beads has no account, no ads, no analytics and requests no internet permission.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsDeleteLocalData.
  ///
  /// In en, this message translates to:
  /// **'Delete local data'**
  String get settingsDeleteLocalData;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all local data?'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your settings, profiles and match history from this device. This cannot be undone.'**
  String get settingsDeleteConfirmBody;

  /// No description provided for @commonOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
