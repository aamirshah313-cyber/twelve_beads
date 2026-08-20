// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'بارہ گوٹی';

  @override
  String get navPlay => 'کھیلیں';

  @override
  String get navHowToPlay => 'کھیلنے کا طریقہ';

  @override
  String get navProfile => 'پروفائل';

  @override
  String get navSettings => 'ترتیبات';

  @override
  String homeCurrentLanguage(String language) {
    return 'زبان: $language';
  }

  @override
  String get languageNameEnglish => 'انگریزی';

  @override
  String get languageNameUrdu => 'اردو';

  @override
  String get gameScreenTitle => 'نیا میچ';

  @override
  String get gameModeLabel => 'موڈ';

  @override
  String get gameModeTwoPlayer => 'دو کھلاڑی';

  @override
  String get gameModeVsMachine => 'کمپیوٹر کے خلاف';

  @override
  String get playerOneNameLabel => 'کھلاڑی 1 کا نام';

  @override
  String get playerTwoNameLabel => 'کھلاڑی 2 کا نام';

  @override
  String get firstTurnLabel => 'پہلی باری';

  @override
  String get firstTurnRandom => 'بے ترتیب';

  @override
  String get firstTurnPlayerOne => 'کھلاڑی 1';

  @override
  String get firstTurnPlayerTwo => 'کھلاڑی 2';

  @override
  String get difficultyLabel => 'مشکل کی سطح';

  @override
  String get difficultyEasy => 'آسان';

  @override
  String get difficultyMedium => 'درمیانہ';

  @override
  String get difficultyDifficult => 'مشکل';

  @override
  String get timerLabel => 'ٹائمر';

  @override
  String get timerOff => 'بند';

  @override
  String get timerCustom => 'مخصوص';

  @override
  String get timerCustomMinutesLabel => 'مخصوص منٹ';

  @override
  String get perMoveTimerLabel => 'فی چال ٹائمر';

  @override
  String get timerCustomSecondsLabel => 'مخصوص سیکنڈ';

  @override
  String get startMatchButton => 'میچ شروع کریں';

  @override
  String get engineNotReadyMessage =>
      'میچ کا انجن ابھی تیار نہیں ہوا — یہ بعد کے مرحلے میں شامل کیا جائے گا۔ آپ کی ترتیبات محفوظ کر لی گئی ہیں۔';

  @override
  String get machineOpponentName => 'مشین';

  @override
  String get machineThinkingLabel => 'مشین سوچ رہی ہے…';

  @override
  String get matchScreenTitle => 'میچ';

  @override
  String turnBanner(String name) {
    return '$name کی باری';
  }

  @override
  String get forcedCaptureBanner => 'گوٹ مارنا ممکن ہے — آپ کو گوٹ مارنا ہوگی';

  @override
  String pieceNodeLabelOwn(String name) {
    return '$name کی گوٹی';
  }

  @override
  String get pieceNodeLabelEmpty => 'خالی جنکشن';

  @override
  String get pieceNodeLegalMove => '، جائز چال';

  @override
  String get pieceNodeLegalCapture => '، جائز گوٹ';

  @override
  String get pieceNodeSelected => '، منتخب';

  @override
  String get pieceNodeLastMove => '، پچھلی چال';

  @override
  String get pauseButton => 'روکیں';

  @override
  String get resumeButton => 'جاری رکھیں';

  @override
  String get restartButton => 'دوبارہ شروع کریں';

  @override
  String get resignButton => 'ہار مانیں';

  @override
  String get undoButton => 'واپس لیں';

  @override
  String get pausedOverlayTitle => 'رکا ہوا';

  @override
  String get pausedOverlayBody =>
      'گھڑی رکی ہوئی ہے۔ جاری رکھنے کے لیے \'جاری رکھیں\' دبائیں۔';

  @override
  String get restartConfirmTitle => 'یہ میچ دوبارہ شروع کریں؟';

  @override
  String get restartConfirmBody =>
      'موجودہ میچ فوری طور پر ختم ہو جائے گا اور نیا میچ شروع ہوگا۔ اسے واپس نہیں لایا جا سکتا۔';

  @override
  String get resignConfirmTitle => 'یہ میچ ہار مانیں؟';

  @override
  String resignConfirmBody(String name) {
    return '$name فوری طور پر میچ ہار جائے گا۔';
  }

  @override
  String get resignConfirmAction => 'ہار مانیں';

  @override
  String matchOverWinnerTitle(String name) {
    return '$name جیت گیا';
  }

  @override
  String get matchOverDrawTitle => 'برابر';

  @override
  String get matchOverReasonElimination =>
      'حریف کی تمام گوٹیاں ماری جا چکی ہیں۔';

  @override
  String matchOverReasonNoLegalMoves(String name) {
    return '$name کے پاس کوئی جائز چال نہیں تھی۔';
  }

  @override
  String matchOverReasonResignation(String name) {
    return '$name نے ہار مان لی۔';
  }

  @override
  String matchOverReasonTimeout(String name) {
    return '$name کا وقت ختم ہو گیا۔';
  }

  @override
  String get matchOverReasonNoCaptureLimit =>
      '40 باریوں تک کوئی گوٹ نہیں ماری گئی۔';

  @override
  String get matchOverNewMatchButton => 'نیا میچ';

  @override
  String get matchOverHomeButton => 'ہوم';

  @override
  String get timeUpMessage => 'وقت ختم';

  @override
  String nodePosition(int row, int column) {
    return 'قطار $row، کالم $column';
  }

  @override
  String moveAnnouncement(String actor, String source, String destination) {
    return '$actor نے $source سے $destination تک چال چلی';
  }

  @override
  String captureAnnouncement(String actor, String source, String destination) {
    return '$actor نے گوٹ ماری، $source سے $destination تک';
  }

  @override
  String chainStepAnnouncement(int step) {
    return 'سلسلہ وار گوٹ، مرحلہ $step';
  }

  @override
  String get opponentMoveInProgress => 'چال جاری ہے';

  @override
  String get quickChatButtonTooltip => 'فوری بات';

  @override
  String get quickChatSheetTitle => 'فوری پیغام بھیجیں';

  @override
  String get quickChatGoodMove => 'اچھی چال';

  @override
  String get quickChatYourTurn => 'آپ کی باری';

  @override
  String get quickChatWellPlayed => 'خوب کھیلا';

  @override
  String get quickChatNiceTry => 'اچھی کوشش';

  @override
  String get quickChatOneMoment => 'ایک لمحہ';

  @override
  String get quickChatGoodGame => 'اچھا میچ';

  @override
  String quickChatBubble(String name, String phrase) {
    return '$name: $phrase';
  }

  @override
  String get rulesScreenTitle => 'کھیلنے کا طریقہ';

  @override
  String get rulesBoardHeading => 'بورڈ';

  @override
  String get rulesBoardBody =>
      'بورڈ میں 5×5 گرڈ کی صورت میں 25 جنکشن ہیں۔ ہر جنکشن اپنے افقی اور عمودی ہمسایہ جنکشنز سے جڑا ہوا ہے، اور 16 چھوٹے مربعوں میں سے ہر ایک میں دونوں اخترن لکیریں بھی موجود ہیں — اس لیے زیادہ تر جنکشن 8 سمتوں تک جڑے ہوتے ہیں۔ ہر فریق 12 گوٹیوں کے ساتھ آغاز کرتا ہے: اپنے قریب ترین دو مکمل قطاریں، جمع درمیانی قطار کے دو قریب ترین جنکشن۔ صرف بالکل درمیانی جنکشن خالی سے شروع ہوتا ہے۔';

  @override
  String get rulesMovementHeading => 'چال اور گوٹ مارنا';

  @override
  String get rulesMovementBody =>
      'گوٹی کسی بھی جڑی ہوئی لکیر پر، کسی بھی سمت میں، ایک قدم چل کر خالی جنکشن پر جاتی ہے۔ گوٹ مارنے کے لیے سیدھی لکیر میں ملحقہ حریف گوٹی کے اوپر سے چھلانگ لگا کر اس سے بالکل آگے خالی جنکشن پر اترنا ہوتا ہے، جس سے چھلانگ لگائی گئی گوٹی ہٹا دی جاتی ہے۔ اگر گوٹ مارنا ممکن ہو تو سادہ چال کی بجائے گوٹ مارنا لازمی ہے۔ اگر اس گوٹ کے بعد اسی مقام سے مزید گوٹ مارنا ممکن ہو تو جب تک ممکن ہو، مسلسل گوٹ مارنا لازمی ہے۔';

  @override
  String get rulesWinningHeading => 'جیت';

  @override
  String get rulesWinningBody =>
      'آپ حریف کی تمام گوٹیاں مار کر، یا اسے اس کی باری پر کوئی جائز چال نہ چھوڑ کر جیتتے ہیں۔ اگر لگاتار 40 باریوں تک کوئی گوٹ نہ ماری جائے تو میچ برابر قرار پاتا ہے۔';

  @override
  String get rulesVariantLabel => 'قاعدہ: کلاسک';

  @override
  String get rulesOpenQuestionsHeading => 'طے شدہ اصول، تبدیلی کے لیے کھلے';

  @override
  String get rulesOpenQuestionsBody =>
      'یہ قواعد اس طرز کے بورڈ کے لیے مناسب طے شدہ اصول استعمال کرتے ہیں، نہ کہ کسی تصدیق شدہ علاقائی ماخذ کے: زیادہ سے زیادہ گوٹ مارنے کی کوئی شرط نہیں (کوئی بھی جائز گوٹ کافی ہے)، اور حفاظتی تدبیر کے طور پر 40 باریوں کی بغیر-گوٹ حد، نہ کہ کوئی روایتی تکراری اصول۔ ان کی تبدیلی کے لیے کسی بھی وقت درخواست کریں۔';

  @override
  String get profileScreenTitle => 'پروفائل';

  @override
  String get profileDefaultName => 'کھلاڑی';

  @override
  String get profileEditNameTooltip => 'ڈسپلے نام میں ترمیم کریں';

  @override
  String get profileEditNameTitle => 'ڈسپلے نام';

  @override
  String get profileStatsMatches => 'میچز';

  @override
  String get profileStatsWins => 'جیت';

  @override
  String get profileStatsLosses => 'شکست';

  @override
  String get profileStatsDraws => 'برابر';

  @override
  String get profileStatsStreak => 'موجودہ سلسلہ';

  @override
  String get profileStatsCaptures => 'گوٹیں ماری گئیں';

  @override
  String get profileBadgesHeading => 'بیجز';

  @override
  String get profileNoBadgesYet => 'ابھی تک کوئی بیج حاصل نہیں ہوا';

  @override
  String get profileNoMatchesYet => 'ابھی تک کوئی میچ نہیں کھیلا گیا';

  @override
  String get profileHistoryHeading => 'حالیہ میچز';

  @override
  String get badgeFirstWinName => 'پہلی جیت';

  @override
  String get badgeFirstWinDescription => 'اپنا پہلا میچ جیتیں۔';

  @override
  String get badgeFiveMatchesName => 'پانچ میچز';

  @override
  String get badgeFiveMatchesDescription => 'پانچ میچز کھیلیں۔';

  @override
  String get badgeCaptureSpecialistName => 'گوٹ ماہر';

  @override
  String get badgeCaptureSpecialistDescription =>
      'ایک ہی میچ میں 5 گوٹیاں ماریں۔';

  @override
  String get badgeThreeWinStreakName => 'تین جیتوں کا سلسلہ';

  @override
  String get badgeThreeWinStreakDescription => 'لگاتار تین میچز جیتیں۔';

  @override
  String get badgeFastFinishName => 'تیز اختتام';

  @override
  String get badgeFastFinishDescription => '12 یا کم چالوں میں میچ جیتیں۔';

  @override
  String get badgePatientPlayerName => 'صابر کھلاڑی';

  @override
  String get badgePatientPlayerDescription =>
      '60 یا زیادہ چالوں تک چلنے والا میچ کھیلیں۔';

  @override
  String get historyOutcomeWin => 'جیت';

  @override
  String get historyOutcomeLoss => 'شکست';

  @override
  String get historyOutcomeDraw => 'برابر';

  @override
  String historyOpponentMachine(String difficulty) {
    return 'بمقابلہ مشین ($difficulty)';
  }

  @override
  String historyOpponentPlayer(String name) {
    return 'بمقابلہ $name';
  }

  @override
  String historyMoveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count چالیں',
      one: '$count چال',
    );
    return '$_temp0';
  }

  @override
  String get resumeMatchAvailableTitle => 'آپ کا ایک میچ جاری ہے';

  @override
  String get resumeMatchButton => 'جاری رکھیں';

  @override
  String get discardMatchButton => 'مسترد کریں';

  @override
  String get discardMatchConfirmTitle => 'اس میچ کو مسترد کریں؟';

  @override
  String get discardMatchConfirmBody =>
      'جاری میچ مستقل طور پر مسترد ہو جائے گا۔ اسے واپس نہیں لایا جا سکتا۔';

  @override
  String get settingsScreenTitle => 'ترتیبات';

  @override
  String get settingsLanguageLabel => 'زبان';

  @override
  String get settingsSoundLabel => 'آواز';

  @override
  String get settingsHapticsLabel => 'ہیپٹک تاثرات';

  @override
  String get settingsReducedMotionLabel => 'کم حرکت';

  @override
  String get reducedMotionSystem => 'نظام کے مطابق';

  @override
  String get settingsHighContrastLabel => 'زیادہ تضاد';

  @override
  String get settingsVisualQualityLabel => 'بصری معیار';

  @override
  String get visualQualityAuto => 'خودکار';

  @override
  String get visualQualityLow => 'کم';

  @override
  String get visualQualityStandard => 'معیاری';

  @override
  String get visualQualityHigh => 'اعلیٰ';

  @override
  String get settingsTimerDefaultLabel => 'طے شدہ ٹائمر';

  @override
  String get settingsPrivacyHeading => 'رازداری';

  @override
  String get settingsPrivacyBody =>
      'تمام پروفائلز، میچ کی تاریخ اور فوری چیٹ اسی آلے پر محفوظ رہتے ہیں۔ بارہ گوٹی میں کوئی اکاؤنٹ، اشتہارات یا تجزیات شامل نہیں اور نہ ہی انٹرنیٹ کی اجازت درکار ہے۔';

  @override
  String get settingsDeleteLocalData => 'مقامی ڈیٹا حذف کریں';

  @override
  String get settingsDeleteConfirmTitle => 'تمام مقامی ڈیٹا حذف کریں؟';

  @override
  String get settingsDeleteConfirmBody =>
      'اس سے آپ کی ترتیبات، پروفائل، بیجز، میچ کی تاریخ اور کوئی بھی جاری میچ اس آلے سے مستقل طور پر حذف ہو جائیں گے۔ اسے واپس نہیں لایا جا سکتا۔';

  @override
  String get commonOn => 'آن';

  @override
  String get commonOff => 'آف';

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonDelete => 'حذف کریں';

  @override
  String get commonSave => 'محفوظ کریں';
}
