// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Twelve Beads';

  @override
  String get navPlay => 'Play';

  @override
  String get navHowToPlay => 'How to Play';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String homeCurrentLanguage(String language) {
    return 'Language: $language';
  }

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameUrdu => 'Urdu';

  @override
  String get gameScreenTitle => 'New Match';

  @override
  String get gameModeLabel => 'Mode';

  @override
  String get gameModeTwoPlayer => 'Two Players';

  @override
  String get gameModeVsMachine => 'Vs Machine';

  @override
  String get playerOneNameLabel => 'Player 1 name';

  @override
  String get playerTwoNameLabel => 'Player 2 name';

  @override
  String get firstTurnLabel => 'First turn';

  @override
  String get firstTurnRandom => 'Random';

  @override
  String get firstTurnPlayerOne => 'Player 1';

  @override
  String get firstTurnPlayerTwo => 'Player 2';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyDifficult => 'Difficult';

  @override
  String get timerLabel => 'Timer';

  @override
  String get timerOff => 'Off';

  @override
  String get startMatchButton => 'Start Match';

  @override
  String get engineNotReadyMessage =>
      'The match engine isn\'t built yet — that\'s a later phase. Your setup has been saved.';

  @override
  String get rulesScreenTitle => 'How to Play';

  @override
  String get rulesBoardHeading => 'The Board';

  @override
  String get rulesBoardBody =>
      'The board has 25 junctions arranged in a 5×5 grid. Every junction is connected to its horizontal and vertical neighbors, and every one of the 16 small squares also has both diagonal lines drawn — so most junctions connect in up to 8 directions. Each side starts with 12 beads: two full rows closest to that side, plus the two middle-row junctions nearest to it. Only the very center junction starts empty.';

  @override
  String get rulesMovementHeading => 'Movement & Captures';

  @override
  String get rulesMovementBody =>
      'A bead moves one step along any connected line, in any direction, to an empty junction. A capture jumps in a straight line over an adjacent opponent bead onto an empty junction directly beyond it, removing the jumped bead. If any capture is available, you must capture rather than make a simple move. If that capture lands somewhere with another capture available, you must continue jumping until no more captures remain from that spot.';

  @override
  String get rulesWinningHeading => 'Winning';

  @override
  String get rulesWinningBody =>
      'You win by capturing every one of your opponent\'s beads, or by leaving them with no legal move on their turn. A match with no capture for 40 turns in a row ends in a draw.';

  @override
  String get rulesVariantLabel => 'Ruleset: Classic';

  @override
  String get rulesOpenQuestionsHeading => 'Defaults, open to change';

  @override
  String get rulesOpenQuestionsBody =>
      'These rules use sensible defaults for this style of board rather than a confirmed regional source: no maximum-capture requirement (any legal capture is enough), and a 40-turn no-capture limit as a safeguard rather than a traditional repetition rule. Ask to change these any time.';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileDefaultName => 'Player';

  @override
  String get profileStatsMatches => 'Matches';

  @override
  String get profileStatsWins => 'Wins';

  @override
  String get profileStatsLosses => 'Losses';

  @override
  String get profileStatsDraws => 'Draws';

  @override
  String get profileStatsStreak => 'Current streak';

  @override
  String get profileStatsCaptures => 'Captures';

  @override
  String get profileBadgesHeading => 'Badges';

  @override
  String get profileNoBadgesYet => 'No badges earned yet';

  @override
  String get profileNoMatchesYet => 'No matches played yet';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsSoundLabel => 'Sound';

  @override
  String get settingsHapticsLabel => 'Haptics';

  @override
  String get settingsReducedMotionLabel => 'Reduced motion';

  @override
  String get reducedMotionSystem => 'System';

  @override
  String get settingsHighContrastLabel => 'High contrast';

  @override
  String get settingsVisualQualityLabel => 'Visual quality';

  @override
  String get visualQualityAuto => 'Auto';

  @override
  String get visualQualityLow => 'Low';

  @override
  String get visualQualityStandard => 'Standard';

  @override
  String get visualQualityHigh => 'High';

  @override
  String get settingsTimerDefaultLabel => 'Default timer';

  @override
  String get settingsPrivacyHeading => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'All profiles, match history and quick chat stay on this device. Twelve Beads has no account, no ads, no analytics and requests no internet permission.';

  @override
  String get settingsDeleteLocalData => 'Delete local data';

  @override
  String get settingsDeleteConfirmTitle => 'Delete all local data?';

  @override
  String get settingsDeleteConfirmBody =>
      'This permanently removes your settings, profiles and match history from this device. This cannot be undone.';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';
}
