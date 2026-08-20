/// Stable quick-chat phrase identifiers, per the "local overlay tied to the
/// active side, rate-limited, localized, and dismisses automatically"
/// contract in 05-ai-and-gameplay-systems.md. Purely decorative/social —
/// per the same spec, quick chat must never be required to understand game
/// state, so its content is intentionally limited to a fixed preset list
/// (no free text, no transmission).
class QuickChatPhraseIds {
  static const goodMove = 'good_move';
  static const yourTurn = 'your_turn';
  static const wellPlayed = 'well_played';
  static const niceTry = 'nice_try';
  static const oneMoment = 'one_moment';
  static const goodGame = 'good_game';

  static const all = [
    goodMove,
    yourTurn,
    wellPlayed,
    niceTry,
    oneMoment,
    goodGame,
  ];
}
