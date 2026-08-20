import '../../../core/l10n/gen/app_localizations.dart';
import '../application/quick_chat_phrases.dart';

/// Localized text for a quick-chat phrase id. Falls back to the raw id
/// (never a crash) for an id this build doesn't recognize.
String describeQuickChatPhrase(AppLocalizations l10n, String phraseId) {
  return switch (phraseId) {
    QuickChatPhraseIds.goodMove => l10n.quickChatGoodMove,
    QuickChatPhraseIds.yourTurn => l10n.quickChatYourTurn,
    QuickChatPhraseIds.wellPlayed => l10n.quickChatWellPlayed,
    QuickChatPhraseIds.niceTry => l10n.quickChatNiceTry,
    QuickChatPhraseIds.oneMoment => l10n.quickChatOneMoment,
    QuickChatPhraseIds.goodGame => l10n.quickChatGoodGame,
    _ => phraseId,
  };
}
