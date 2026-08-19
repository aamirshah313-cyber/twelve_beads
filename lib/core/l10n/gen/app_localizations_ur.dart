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
  String get startMatchButton => 'میچ شروع کریں';

  @override
  String get engineNotReadyMessage =>
      'میچ کا انجن ابھی تیار نہیں ہوا — یہ بعد کے مرحلے میں شامل کیا جائے گا۔ آپ کی ترتیبات محفوظ کر لی گئی ہیں۔';

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
      'گوٹی کسی بھی جڑی ہوئی لکیر پر ایک قدم چل کر خالی جنکشن پر جاتی ہے۔ گوٹ مارنے کے لیے سیدھی لکیر میں ملحقہ حریف گوٹی کے اوپر سے چھلانگ لگا کر اس سے بالکل آگے خالی جنکشن پر اترنا ہوتا ہے، جس سے چھلانگ لگائی گئی گوٹی ہٹا دی جاتی ہے۔';

  @override
  String get rulesOpenQuestionsHeading => 'ابھی حتمی نہیں';

  @override
  String get rulesOpenQuestionsBody =>
      'درج ذیل تفصیلی قواعد ابھی زیر تصدیق ہیں اور ریلیز سے پہلے تبدیل ہو سکتے ہیں: کیا گوٹ مارنا لازمی ہے جب دستیاب ہو، کیا شروع ہونے کے بعد سلسلہ وار گوٹ مارنا جاری رکھنا لازمی ہے، برابری/تکرار کیسے طے ہوگی، جیت کی حتمی شرط، پیچھے کی چال، اور واپسی (undo) کی دستیابی۔';

  @override
  String get profileScreenTitle => 'پروفائل';

  @override
  String get profileDefaultName => 'کھلاڑی';

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
      'اس سے آپ کی ترتیبات، پروفائلز اور میچ کی تاریخ اس آلے سے مستقل طور پر حذف ہو جائیں گی۔ اسے واپس نہیں لایا جا سکتا۔';

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
