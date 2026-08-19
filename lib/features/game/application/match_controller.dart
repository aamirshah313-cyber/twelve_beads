import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/board/board_graph.dart';
import '../../../game/engine/game_action.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/engine/rules_engine.dart';
import '../../../game/engine/side.dart';
import 'game_clock.dart';
import 'match_config.dart';
import 'move_presentation_controller.dart';

/// Immutable UI-facing snapshot of a local match in progress.
class MatchUiState {
  final MatchConfig config;
  final GameState gameState;
  final List<GameAction> actionLog;
  final NodeId? selectedNode;
  final NodeId? lastMoveSource;
  final NodeId? lastMoveDestination;
  final Duration topRemaining;
  final Duration bottomRemaining;
  final bool isPaused;

  const MatchUiState({
    required this.config,
    required this.gameState,
    required this.actionLog,
    required this.selectedNode,
    required this.lastMoveSource,
    required this.lastMoveDestination,
    required this.topRemaining,
    required this.bottomRemaining,
    required this.isPaused,
  });

  factory MatchUiState.initial(MatchConfig config) {
    final total = Duration(minutes: config.timerMinutes);
    return MatchUiState(
      config: config,
      gameState: GameState.initial(
        ruleset: config.ruleset,
        firstTurn: config.firstTurn,
      ),
      actionLog: const [],
      selectedNode: null,
      lastMoveSource: null,
      lastMoveDestination: null,
      topRemaining: total,
      bottomRemaining: total,
      isPaused: false,
    );
  }

  /// The board-and-ruleset-legal actions available right now. Always
  /// derived fresh from [gameState] — never cached/guessed by the UI.
  List<GameAction> get legalActions => legalActionsFor(gameState);

  /// True when every currently legal action is a capture, i.e. the
  /// mandatory-capture rule has been triggered for the side to move.
  bool get forcedCaptureActive =>
      legalActions.isNotEmpty && legalActions.every((a) => a is CaptureAction);

  /// Undo is available only for the single most recently completed action,
  /// and only outside of an in-progress capture chain (D-009 in
  /// docs/spec/DECISIONS.md).
  bool get canUndo =>
      actionLog.isNotEmpty &&
      gameState.mustContinueCaptureFrom == null &&
      gameState.phase == GamePhase.playing;
}

List<GameAction> legalActionsFor(GameState state) => legalActions(state);

NodeId? _sourceOf(GameAction action) => switch (action) {
  MoveAction(:final from) => from,
  CaptureAction(:final from) => from,
  ResignAction() || TimeoutAction() => null,
};

NodeId? _destinationOf(GameAction action) => switch (action) {
  MoveAction(:final to) => to,
  CaptureAction(:final to) => to,
  ResignAction() || TimeoutAction() => null,
};

class MatchController extends Notifier<MatchUiState> {
  MatchController(this.config);

  final MatchConfig config;

  Timer? _timer;
  DateTime? _armedAt;
  Side? _armedSide;
  late final String _matchId;
  int _actionSequence = 0;

  GameClock get _clock => ref.read(gameClockProvider);

  @override
  MatchUiState build() {
    _matchId =
        'local-${identityHashCode(config)}-${DateTime.now().microsecondsSinceEpoch}';
    ref.onDispose(() => _timer?.cancel());
    final initial = MatchUiState.initial(config);
    if (initial.config.timerEnabled) {
      _armClock(initial.gameState.turn);
      // Can't call _startTimer() here: it reads `state`, which isn't set
      // until this build() call returns. Start the periodic timer directly.
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
    return initial;
  }

  void onNodeTapped(NodeId node) {
    if (state.isPaused || state.gameState.phase != GamePhase.playing) return;
    // Defense in depth: BoardWidget already disables its tap targets while
    // a presentation animation is playing, but the domain-adjacent
    // controller must not accept conflicting input either way.
    if (ref.read(movePresentationControllerProvider(config)).isPlaying) return;

    final legal = state.legalActions;

    if (state.selectedNode != null) {
      GameAction? match;
      for (final action in legal) {
        if (_sourceOf(action) == state.selectedNode &&
            _destinationOf(action) == node) {
          match = action;
          break;
        }
      }
      if (match != null) {
        _applyAndUpdate(match);
        return;
      }
    }

    final hasLegalFrom = legal.any((a) => _sourceOf(a) == node);
    if (hasLegalFrom) {
      state = _withSelection(node == state.selectedNode ? null : node);
    } else if (state.selectedNode != null) {
      state = _withSelection(null);
    }
  }

  /// Applies an action chosen outside of direct board taps — currently only
  /// the machine opponent (Phase 5). Goes through the exact same
  /// validation and presentation-timeline wiring as [onNodeTapped]; the
  /// caller is responsible for having derived [action] from this match's
  /// own [MatchUiState.legalActions] (typically via [MachineController]),
  /// never from a separate/stale computation.
  bool applyExternalAction(GameAction action) {
    if (state.isPaused || state.gameState.phase != GamePhase.playing) {
      return false;
    }
    if (!isLegal(state.gameState, action)) return false;
    _applyAndUpdate(action);
    return true;
  }

  void resign(Side side) {
    if (state.gameState.phase != GamePhase.playing) return;
    _cancelPresentation();
    _applyAndUpdate(ResignAction(side));
  }

  void undo() {
    if (!state.canUndo) return;
    _cancelPresentation();
    _freezeClocksIntoState();

    final newLog = state.actionLog.sublist(0, state.actionLog.length - 1);
    final rebuilt = replay(
      ruleset: state.config.ruleset,
      firstTurn: state.config.firstTurn,
      actions: newLog,
      matchId: _matchId,
    );

    state = MatchUiState(
      config: state.config,
      gameState: rebuilt,
      actionLog: newLog,
      selectedNode: null,
      lastMoveSource: newLog.isEmpty ? null : _sourceOf(newLog.last),
      lastMoveDestination: newLog.isEmpty ? null : _destinationOf(newLog.last),
      topRemaining: state.topRemaining,
      bottomRemaining: state.bottomRemaining,
      isPaused: state.isPaused,
    );

    if (!state.isPaused && rebuilt.phase == GamePhase.playing) {
      _armClock(rebuilt.turn);
      _startTimer();
    }
  }

  void pause() {
    if (state.isPaused || state.gameState.phase != GamePhase.playing) return;
    _cancelPresentation();
    _freezeClocksIntoState();
    _cancelTimer();
    state = _withPaused(true);
  }

  void resume() {
    if (!state.isPaused || state.gameState.phase != GamePhase.playing) return;
    state = _withPaused(false);
    _armClock(state.gameState.turn);
    _startTimer();
  }

  void restart() {
    _cancelPresentation();
    _cancelTimer();
    _armedAt = null;
    _armedSide = null;
    _actionSequence = 0;
    final fresh = MatchUiState.initial(state.config);
    state = fresh;
    if (fresh.config.timerEnabled) {
      _armClock(fresh.gameState.turn);
      _startTimer();
    }
  }

  // --- Internal ---------------------------------------------------------

  void _applyAndUpdate(GameAction action) {
    _freezeClocksIntoState();

    final piecesBefore = state.gameState.pieces;
    final outcome = apply(
      state.gameState,
      action,
      matchId: _matchId,
      actionSequence: _actionSequence++,
    );

    final source = _sourceOf(action) ?? state.lastMoveSource;
    final destination = _destinationOf(action) ?? state.lastMoveDestination;

    state = MatchUiState(
      config: state.config,
      gameState: outcome.state,
      actionLog: [...state.actionLog, action],
      selectedNode: null,
      lastMoveSource: source,
      lastMoveDestination: destination,
      topRemaining: state.topRemaining,
      bottomRemaining: state.bottomRemaining,
      isPaused: state.isPaused,
    );

    if (outcome.state.phase == GamePhase.finished || state.isPaused) {
      _cancelTimer();
    } else {
      _armClock(outcome.state.turn);
      _startTimer();
    }

    // Only Move/Capture describe an actual board transition to animate;
    // Resign/Timeout have no source/destination to play back.
    if (action is MoveAction || action is CaptureAction) {
      ref
          .read(movePresentationControllerProvider(config).notifier)
          .enqueue(piecesBefore, outcome.event);
    }
    if (outcome.state.phase == GamePhase.finished) {
      ref.read(hapticsPortProvider).matchEnd();
    }
  }

  void _cancelPresentation() {
    ref
        .read(movePresentationControllerProvider(config).notifier)
        .cancelAndSnapToFinal();
  }

  MatchUiState _withSelection(NodeId? node) => MatchUiState(
    config: state.config,
    gameState: state.gameState,
    actionLog: state.actionLog,
    selectedNode: node,
    lastMoveSource: state.lastMoveSource,
    lastMoveDestination: state.lastMoveDestination,
    topRemaining: state.topRemaining,
    bottomRemaining: state.bottomRemaining,
    isPaused: state.isPaused,
  );

  MatchUiState _withPaused(bool paused) => MatchUiState(
    config: state.config,
    gameState: state.gameState,
    actionLog: state.actionLog,
    selectedNode: state.selectedNode,
    lastMoveSource: state.lastMoveSource,
    lastMoveDestination: state.lastMoveDestination,
    topRemaining: state.topRemaining,
    bottomRemaining: state.bottomRemaining,
    isPaused: paused,
  );

  void _armClock(Side side) {
    _armedAt = _clock.now();
    _armedSide = side;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    if (!state.config.timerEnabled) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Duration _elapsedSinceArm() {
    final armedAt = _armedAt;
    if (armedAt == null) return Duration.zero;
    return _clock.now().difference(armedAt);
  }

  ({Duration top, Duration bottom}) _liveRemaining() {
    var top = state.topRemaining;
    var bottom = state.bottomRemaining;
    final elapsed = _elapsedSinceArm();
    if (_armedSide == Side.top) {
      top -= elapsed;
      if (top < Duration.zero) top = Duration.zero;
    } else if (_armedSide == Side.bottom) {
      bottom -= elapsed;
      if (bottom < Duration.zero) bottom = Duration.zero;
    }
    return (top: top, bottom: bottom);
  }

  void _freezeClocksIntoState() {
    if (!state.config.timerEnabled) return;
    final live = _liveRemaining();
    state = MatchUiState(
      config: state.config,
      gameState: state.gameState,
      actionLog: state.actionLog,
      selectedNode: state.selectedNode,
      lastMoveSource: state.lastMoveSource,
      lastMoveDestination: state.lastMoveDestination,
      topRemaining: live.top,
      bottomRemaining: live.bottom,
      isPaused: state.isPaused,
    );
    _armedAt = null;
    _armedSide = null;
  }

  void _onTick() {
    if (!state.config.timerEnabled || state.isPaused) return;
    final live = _liveRemaining();
    state = MatchUiState(
      config: state.config,
      gameState: state.gameState,
      actionLog: state.actionLog,
      selectedNode: state.selectedNode,
      lastMoveSource: state.lastMoveSource,
      lastMoveDestination: state.lastMoveDestination,
      topRemaining: live.top,
      bottomRemaining: live.bottom,
      isPaused: state.isPaused,
    );
    // Re-arm from now: state.topRemaining/bottomRemaining already reflect
    // elapsed time up to this instant, so the next tick must measure
    // elapsed since *now*, not keep accumulating from the original arm —
    // otherwise each tick double-subtracts already-applied elapsed time.
    _armedAt = _clock.now();

    final activeRemaining = state.gameState.turn == Side.top
        ? live.top
        : live.bottom;
    if (activeRemaining <= Duration.zero) {
      _cancelTimer();
      _armedAt = null;
      _applyAndUpdate(TimeoutAction(state.gameState.turn));
    }
  }
}

final matchControllerProvider = NotifierProvider.family
    .autoDispose<MatchController, MatchUiState, MatchConfig>(
      MatchController.new,
    );
