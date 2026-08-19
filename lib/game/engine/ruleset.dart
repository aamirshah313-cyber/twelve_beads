/// A named, versioned bundle of match rules. Per `docs/spec/DECISIONS.md`,
/// [classicAlquerque] resolves the open rules questions (D-003..D-008) using
/// the well-established traditional Alquerque ruleset — the same family of
/// game this board's 12-a-side, empty-center starting layout belongs to.
/// This is a chosen, documented default, not a claim of verified regional
/// authority: it is deliberately a named [Ruleset] rather than a hardcoded
/// rule so a different regional variant can be added later without engine
/// changes.
class Ruleset {
  /// Stable identifier persisted in [GameState] and [MoveEvent] data.
  final String id;

  /// Bumped whenever this ruleset's behavior changes, so persisted matches
  /// and replays can detect an incompatible rules version.
  final int version;

  final String displayName;

  /// D-003/resolved: no separate drop/placement phase — all 24 seeded
  /// pieces move from their starting nodes from turn one.
  ///
  /// D-004/resolved: movement (simple moves and jumps alike) is
  /// omnidirectional along any declared graph edge — there is no
  /// forward-only restriction and no promotion/king concept. This is
  /// structural (the engine always uses [BoardGraph] adjacency in every
  /// direction), so it has no explicit flag here.
  ///
  /// D-005/resolved: if true, a player holding at least one available
  /// capture (anywhere on the board) must play a capture, not a simple move.
  final bool mandatoryCapture;

  /// D-006/resolved: if true, a capture that lands somewhere with a further
  /// capture available must continue the chain before the turn can pass.
  final bool chainCaptureMandatory;

  /// D-007/resolved (engineering safeguard, not a traditional rule): number
  /// of plies without a capture after which the match is declared a draw,
  /// so an engine-level match is guaranteed to terminate. 0 disables it.
  final int noCaptureMoveLimitForDraw;

  /// D-008/resolved: if true, a player with no legal action on their turn
  /// loses (stalemate-as-loss); if false, it is a draw.
  final bool stalemateIsLossForPlayerToMove;

  const Ruleset({
    required this.id,
    required this.version,
    required this.displayName,
    required this.mandatoryCapture,
    required this.chainCaptureMandatory,
    required this.noCaptureMoveLimitForDraw,
    required this.stalemateIsLossForPlayerToMove,
  });

  static const classicAlquerque = Ruleset(
    id: 'classic_alquerque',
    version: 1,
    displayName: 'Classic',
    mandatoryCapture: true,
    chainCaptureMandatory: true,
    noCaptureMoveLimitForDraw: 40,
    stalemateIsLossForPlayerToMove: true,
  );

  static const Map<String, Ruleset> knownRulesets = {
    'classic_alquerque': classicAlquerque,
  };
}
