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

  /// No description provided for @timerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timerCustom;

  /// No description provided for @timerCustomMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom minutes'**
  String get timerCustomMinutesLabel;

  /// No description provided for @perMoveTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Per-move timer'**
  String get perMoveTimerLabel;

  /// No description provided for @timerCustomSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom seconds'**
  String get timerCustomSecondsLabel;

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

  /// No description provided for @machineOpponentName.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get machineOpponentName;

  /// No description provided for @machineThinkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Machine is thinking…'**
  String get machineThinkingLabel;

  /// No description provided for @matchScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchScreenTitle;

  /// No description provided for @turnBanner.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String turnBanner(String name);

  /// No description provided for @forcedCaptureBanner.
  ///
  /// In en, this message translates to:
  /// **'Capture available — you must capture'**
  String get forcedCaptureBanner;

  /// No description provided for @pieceNodeLabelOwn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s bead'**
  String pieceNodeLabelOwn(String name);

  /// No description provided for @pieceNodeLabelEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty junction'**
  String get pieceNodeLabelEmpty;

  /// No description provided for @pieceNodeLegalMove.
  ///
  /// In en, this message translates to:
  /// **', legal move'**
  String get pieceNodeLegalMove;

  /// No description provided for @pieceNodeLegalCapture.
  ///
  /// In en, this message translates to:
  /// **', legal capture'**
  String get pieceNodeLegalCapture;

  /// No description provided for @pieceNodeSelected.
  ///
  /// In en, this message translates to:
  /// **', selected'**
  String get pieceNodeSelected;

  /// No description provided for @pieceNodeLastMove.
  ///
  /// In en, this message translates to:
  /// **', last move'**
  String get pieceNodeLastMove;

  /// No description provided for @pauseButton.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseButton;

  /// No description provided for @resumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeButton;

  /// No description provided for @restartButton.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartButton;

  /// No description provided for @resignButton.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resignButton;

  /// No description provided for @undoButton.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoButton;

  /// No description provided for @pausedOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedOverlayTitle;

  /// No description provided for @pausedOverlayBody.
  ///
  /// In en, this message translates to:
  /// **'The clock is stopped. Tap Resume to continue.'**
  String get pausedOverlayBody;

  /// No description provided for @restartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart this match?'**
  String get restartConfirmTitle;

  /// No description provided for @restartConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The current match will end immediately and a new one will start. This cannot be undone.'**
  String get restartConfirmBody;

  /// No description provided for @resignConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign this match?'**
  String get resignConfirmTitle;

  /// No description provided for @resignConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose the match immediately.'**
  String resignConfirmBody(String name);

  /// No description provided for @resignConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resignConfirmAction;

  /// No description provided for @matchOverWinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String matchOverWinnerTitle(String name);

  /// No description provided for @matchOverDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get matchOverDrawTitle;

  /// No description provided for @matchOverReasonElimination.
  ///
  /// In en, this message translates to:
  /// **'All opposing beads were captured.'**
  String get matchOverReasonElimination;

  /// No description provided for @matchOverReasonNoLegalMoves.
  ///
  /// In en, this message translates to:
  /// **'{name} had no legal move.'**
  String matchOverReasonNoLegalMoves(String name);

  /// No description provided for @matchOverReasonResignation.
  ///
  /// In en, this message translates to:
  /// **'{name} resigned.'**
  String matchOverReasonResignation(String name);

  /// No description provided for @matchOverReasonTimeout.
  ///
  /// In en, this message translates to:
  /// **'{name} ran out of time.'**
  String matchOverReasonTimeout(String name);

  /// No description provided for @matchOverReasonNoCaptureLimit.
  ///
  /// In en, this message translates to:
  /// **'No capture was made in 40 turns.'**
  String get matchOverReasonNoCaptureLimit;

  /// No description provided for @matchOverNewMatchButton.
  ///
  /// In en, this message translates to:
  /// **'New Match'**
  String get matchOverNewMatchButton;

  /// No description provided for @matchOverHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get matchOverHomeButton;

  /// No description provided for @timeUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get timeUpMessage;

  /// Plain-language description of a board junction for screen readers; never expose internal node IDs.
  ///
  /// In en, this message translates to:
  /// **'row {row}, column {column}'**
  String nodePosition(int row, int column);

  /// No description provided for @moveAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{actor} moved from {source} to {destination}'**
  String moveAnnouncement(String actor, String source, String destination);

  /// No description provided for @captureAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{actor} captured a bead, moving from {source} to {destination}'**
  String captureAnnouncement(String actor, String source, String destination);

  /// No description provided for @chainStepAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Capture chain, step {step}'**
  String chainStepAnnouncement(int step);

  /// No description provided for @opponentMoveInProgress.
  ///
  /// In en, this message translates to:
  /// **'Move in progress'**
  String get opponentMoveInProgress;

  /// No description provided for @quickChatButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick chat'**
  String get quickChatButtonTooltip;

  /// No description provided for @quickChatSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a quick chat'**
  String get quickChatSheetTitle;

  /// No description provided for @quickChatGoodMove.
  ///
  /// In en, this message translates to:
  /// **'Good move'**
  String get quickChatGoodMove;

  /// No description provided for @quickChatYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get quickChatYourTurn;

  /// No description provided for @quickChatWellPlayed.
  ///
  /// In en, this message translates to:
  /// **'Well played'**
  String get quickChatWellPlayed;

  /// No description provided for @quickChatNiceTry.
  ///
  /// In en, this message translates to:
  /// **'Nice try'**
  String get quickChatNiceTry;

  /// No description provided for @quickChatOneMoment.
  ///
  /// In en, this message translates to:
  /// **'One moment'**
  String get quickChatOneMoment;

  /// No description provided for @quickChatGoodGame.
  ///
  /// In en, this message translates to:
  /// **'Good game'**
  String get quickChatGoodGame;

  /// No description provided for @quickChatBubble.
  ///
  /// In en, this message translates to:
  /// **'{name}: {phrase}'**
  String quickChatBubble(String name, String phrase);

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

  /// No description provided for @profileEditNameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit display name'**
  String get profileEditNameTooltip;

  /// No description provided for @profileEditNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileEditNameTitle;

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

  /// No description provided for @profileHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent matches'**
  String get profileHistoryHeading;

  /// No description provided for @badgeFirstWinName.
  ///
  /// In en, this message translates to:
  /// **'First Win'**
  String get badgeFirstWinName;

  /// No description provided for @badgeFirstWinDescription.
  ///
  /// In en, this message translates to:
  /// **'Win your first match.'**
  String get badgeFirstWinDescription;

  /// No description provided for @badgeFiveMatchesName.
  ///
  /// In en, this message translates to:
  /// **'Five Matches'**
  String get badgeFiveMatchesName;

  /// No description provided for @badgeFiveMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Play five matches.'**
  String get badgeFiveMatchesDescription;

  /// No description provided for @badgeCaptureSpecialistName.
  ///
  /// In en, this message translates to:
  /// **'Capture Specialist'**
  String get badgeCaptureSpecialistName;

  /// No description provided for @badgeCaptureSpecialistDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture 5 beads in a single match.'**
  String get badgeCaptureSpecialistDescription;

  /// No description provided for @badgeThreeWinStreakName.
  ///
  /// In en, this message translates to:
  /// **'Three-Win Streak'**
  String get badgeThreeWinStreakName;

  /// No description provided for @badgeThreeWinStreakDescription.
  ///
  /// In en, this message translates to:
  /// **'Win three matches in a row.'**
  String get badgeThreeWinStreakDescription;

  /// No description provided for @badgeFastFinishName.
  ///
  /// In en, this message translates to:
  /// **'Fast Finish'**
  String get badgeFastFinishName;

  /// No description provided for @badgeFastFinishDescription.
  ///
  /// In en, this message translates to:
  /// **'Win a match in 12 moves or fewer.'**
  String get badgeFastFinishDescription;

  /// No description provided for @badgePatientPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Patient Player'**
  String get badgePatientPlayerName;

  /// No description provided for @badgePatientPlayerDescription.
  ///
  /// In en, this message translates to:
  /// **'Play a match that lasts 60 moves or more.'**
  String get badgePatientPlayerDescription;

  /// No description provided for @historyOutcomeWin.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get historyOutcomeWin;

  /// No description provided for @historyOutcomeLoss.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get historyOutcomeLoss;

  /// No description provided for @historyOutcomeDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get historyOutcomeDraw;

  /// No description provided for @historyOpponentMachine.
  ///
  /// In en, this message translates to:
  /// **'vs Machine ({difficulty})'**
  String historyOpponentMachine(String difficulty);

  /// No description provided for @historyOpponentPlayer.
  ///
  /// In en, this message translates to:
  /// **'vs {name}'**
  String historyOpponentPlayer(String name);

  /// No description provided for @historyMoveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} moves'**
  String historyMoveCount(int count);

  /// No description provided for @resumeMatchAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'You have a match in progress'**
  String get resumeMatchAvailableTitle;

  /// No description provided for @resumeMatchButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeMatchButton;

  /// No description provided for @discardMatchButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardMatchButton;

  /// No description provided for @discardMatchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this match?'**
  String get discardMatchConfirmTitle;

  /// No description provided for @discardMatchConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The in-progress match will be permanently discarded. This cannot be undone.'**
  String get discardMatchConfirmBody;

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
  /// **'This permanently removes your settings, profile, badges, match history and any in-progress match from this device. This cannot be undone.'**
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
