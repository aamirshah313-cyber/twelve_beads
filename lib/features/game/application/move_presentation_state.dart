import '../../../game/board/board_graph.dart';
import '../../../game/engine/move_event.dart';
import '../../../game/engine/side.dart';

/// Where a single [MoveEvent] currently is in its visual playback.
enum PresentationPhase { source, travel, captureHighlight, destination }

/// One accepted [MoveEvent] paired with the piece map exactly as it was
/// immediately before that event was applied — everything the presentation
/// layer needs to render the step without ever calling back into the
/// domain engine.
class PresentationStep {
  final Map<NodeId, Side> piecesBefore;
  final MoveEvent event;

  const PresentationStep({required this.piecesBefore, required this.event});
}

/// Presentation-only state: which step (if any) is currently animating, what
/// phase it's in, and what else is queued behind it (used for chained
/// captures, where each jump is its own event). Never holds or derives
/// [GameState] — [MatchController] remains the sole source of truth for the
/// actual game.
class MovePresentationState {
  final PresentationStep? current;
  final List<PresentationStep> queued;
  final PresentationPhase phase;

  /// 0..1 progress within the current `travel` phase only.
  final double travelProgress;

  const MovePresentationState({
    required this.current,
    required this.queued,
    required this.phase,
    required this.travelProgress,
  });

  static const idle = MovePresentationState(
    current: null,
    queued: [],
    phase: PresentationPhase.source,
    travelProgress: 0,
  );

  bool get isPlaying => current != null;
}
