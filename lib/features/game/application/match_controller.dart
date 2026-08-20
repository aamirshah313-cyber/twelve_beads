import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/history/match_history_controller.dart';
import '../../../core/history/match_record.dart';
import '../../../core/profile/profile_controller.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../game/board/board_graph.dart';
import '../../../game/engine/game_action.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/engine/rules_engine.dart';
import '../../../game/engine/side.dart';
import 'game_clock.dart';
import 'match_config.dart';
import 'move_presentation_controller.dart';
import 'saved_game.dart';
import 'saved_game_controller.dart';

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

  /// Remaining time on the current per-move timer, if
  /// [MatchConfig.perMoveTimerEnabled]; null otherwise.
  final Duration? perMoveRemaining;
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
    required this.perMoveRemaining,
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
      perMoveRemaining: config.perMoveTimerEnabled
          ? Duration(seconds: config.perMoveSeconds)
          : null,
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

/// Shared with the presentation layer (player rail countdown coloring) so
/// the visual "running low" cue always matches exactly when
/// [MatchController] actually fires the warning haptic/sound.
const timerWarningThreshold = Duration(seconds: 10);

class MatchController extends Notifier<MatchUiState> {
  MatchController(this.config);

  final MatchConfig config;

  Timer? _timer;
  DateTime? _armedAt;
  Side? _armedSide;
  bool _warnedForCurrentArm = false;
  late final String _matchId;
  int _actionSequence = 0;
  late DateTime _startedAt;
  bool _finalized = false;

  GameClock get _clock => ref.read(gameClockProvider);

  bool get _anyClockEnabled =>
      config.timerEnabled || config.perMoveTimerEnabled;

  Duration? _freshPerMoveRemaining() => config.perMoveTimerEnabled
      ? Duration(seconds: config.perMoveSeconds)
      : null;

  @override
  MatchUiState build() {
    _matchId =
        'local-${identityHashCode(config)}-${DateTime.now().microsecondsSinceEpoch}';
    ref.onDispose(() => _timer?.cancel());

    final pending = ref.read(pendingResumeSnapshotProvider);
    final MatchUiState initial;
    if (pending != null && identical(pending.config, config)) {
      // Consume the hand-off once — a second MatchController build for the
      // same config (e.g. after a hot restart of the widget tree) must not
      // re-hydrate from a now-stale snapshot. Providers can't modify each
      // other synchronously during build(), so this is deferred by one
      // microtask (same pattern as MachineController's initial-turn check).
      Future.microtask(() {
        if (ref.exists(pendingResumeSnapshotProvider)) {
          ref.read(pendingResumeSnapshotProvider.notifier).set(null);
        }
      });
      _startedAt = pending.startedAt;
      final rebuilt = replay(
        ruleset: config.ruleset,
        firstTurn: config.firstTurn,
        actions: pending.actionLog,
        matchId: _matchId,
      );
      _actionSequence = pending.actionLog.length;
      initial = MatchUiState(
        config: config,
        gameState: rebuilt,
        actionLog: pending.actionLog,
        selectedNode: null,
        lastMoveSource: pending.actionLog.isEmpty
            ? null
            : _sourceOf(pending.actionLog.last),
        lastMoveDestination: pending.actionLog.isEmpty
            ? null
            : _destinationOf(pending.actionLog.last),
        topRemaining: pending.topRemaining,
        bottomRemaining: pending.bottomRemaining,
        perMoveRemaining: pending.perMoveRemaining,
        // Land paused: the player must explicitly resume for the clock (and
        // the machine, if any) to start, rather than either silently
        // running in the background.
        isPaused: true,
      );
    } else {
      _startedAt = _clock.now();
      initial = MatchUiState.initial(config);
    }

    if (_anyClockEnabled && !initial.isPaused) {
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
      final newSelection = node == state.selectedNode ? null : node;
      if (newSelection != null) {
        final settings = ref.read(settingsControllerProvider);
        if (settings.hapticsOn) ref.read(hapticsPortProvider).selection();
        if (settings.soundOn) ref.read(soundPortProvider).selection();
      }
      state = _withSelection(newSelection);
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
      // Undo effectively gives the side whose move was undone a fresh
      // attempt — reset the per-move budget rather than carrying forward
      // an arbitrary already-elapsed amount with no historical record of
      // exactly when it was spent.
      perMoveRemaining: _freshPerMoveRemaining(),
      isPaused: state.isPaused,
    );

    if (!state.isPaused && rebuilt.phase == GamePhase.playing) {
      _armClock(rebuilt.turn);
      _startTimer();
    }
    if (newLog.isEmpty) {
      // Undoing back to the very start leaves nothing worth resuming —
      // clear any stale saved snapshot rather than leaving it out of sync.
      ref.read(savedGameControllerProvider.notifier).clear();
    } else {
      _autosave();
    }
  }

  void pause() {
    if (state.isPaused || state.gameState.phase != GamePhase.playing) return;
    _cancelPresentation();
    _freezeClocksIntoState();
    _cancelTimer();
    state = _withPaused(true);
    _autosave();
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
    _finalized = false;
    _startedAt = _clock.now();
    ref.read(savedGameControllerProvider.notifier).clear();
    final fresh = MatchUiState.initial(state.config);
    state = fresh;
    if (_anyClockEnabled) {
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
    // A forced capture chain keeps the same mover and doesn't consume a new
    // per-move budget; only an actual turn change does.
    final turnChanged = outcome.state.turn != state.gameState.turn;

    state = MatchUiState(
      config: state.config,
      gameState: outcome.state,
      actionLog: [...state.actionLog, action],
      selectedNode: null,
      lastMoveSource: source,
      lastMoveDestination: destination,
      topRemaining: state.topRemaining,
      bottomRemaining: state.bottomRemaining,
      perMoveRemaining: turnChanged
          ? _freshPerMoveRemaining()
          : state.perMoveRemaining,
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
      if (ref.read(settingsControllerProvider).hapticsOn) {
        ref.read(hapticsPortProvider).matchEnd();
      }
      _finalizeMatch(outcome.state);
    } else {
      _autosave();
    }
  }

  void _cancelPresentation() {
    ref
        .read(movePresentationControllerProvider(config).notifier)
        .cancelAndSnapToFinal();
  }

  /// Persists the current in-progress match so it can be offered as
  /// "Resume" on next launch. Never called for a still-empty match (nothing
  /// to resume) or a finished one (`_finalizeMatch` clears it instead) —
  /// per "avoid saving a game after it is already terminal".
  void _autosave() {
    if (state.gameState.phase != GamePhase.playing) return;
    if (state.actionLog.isEmpty) return;
    ref
        .read(savedGameControllerProvider.notifier)
        .save(
          SavedGameSnapshot(
            config: config,
            actionLog: state.actionLog,
            topRemaining: state.topRemaining,
            bottomRemaining: state.bottomRemaining,
            perMoveRemaining: state.perMoveRemaining,
            startedAt: _startedAt,
            savedAt: _clock.now(),
          ),
        );
  }

  /// Folds a just-finished match's result into local match history and the
  /// profile's aggregate stats/badges (Phase 6), and clears any saved
  /// resumable snapshot. Runs exactly once per match instance: reachable
  /// only from [_applyAndUpdate] the single time `phase` turns
  /// [GamePhase.finished], since no further action can apply afterward.
  void _finalizeMatch(GameState finalState) {
    if (_finalized) return;
    _finalized = true;

    ref.read(savedGameControllerProvider.notifier).clear();

    final ownSide = config.playerOneSide;
    final events = replayWithEvents(
      ruleset: config.ruleset,
      firstTurn: config.firstTurn,
      actions: state.actionLog,
    ).events;
    final ownCaptures = events
        .where((event) => event.actor == ownSide)
        .fold<int>(0, (sum, event) => sum + event.capturedNodes.length);

    final outcome = matchOutcomeFor(finalState, ownSide);
    final now = _clock.now();

    ref
        .read(matchHistoryControllerProvider.notifier)
        .addRecord(
          MatchRecord(
            id: 'match-${now.microsecondsSinceEpoch}',
            startedAt: _startedAt,
            endedAt: now,
            mode: config.isVsMachine
                ? MatchMode.vsMachine
                : MatchMode.twoPlayer,
            difficulty: config.isVsMachine ? config.difficulty : null,
            playerOneName: config.playerOneName,
            playerTwoName: config.playerTwoName,
            outcome: outcome,
            winReason: finalState.winReason,
            moveCount: state.actionLog.length,
            ownCaptures: ownCaptures,
          ),
        );

    ref
        .read(profileControllerProvider.notifier)
        .applyFinalizedMatch(
          outcome: outcome,
          capturesGained: ownCaptures,
          moveCount: state.actionLog.length,
        );
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
    perMoveRemaining: state.perMoveRemaining,
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
    perMoveRemaining: state.perMoveRemaining,
    isPaused: paused,
  );

  void _armClock(Side side) {
    _armedAt = _clock.now();
    _armedSide = side;
    _warnedForCurrentArm = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_anyClockEnabled) return;
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

  ({Duration top, Duration bottom, Duration? perMove}) _liveRemaining() {
    var top = state.topRemaining;
    var bottom = state.bottomRemaining;
    var perMove = state.perMoveRemaining;
    final elapsed = _elapsedSinceArm();
    if (_armedSide == Side.top) {
      top -= elapsed;
      if (top < Duration.zero) top = Duration.zero;
    } else if (_armedSide == Side.bottom) {
      bottom -= elapsed;
      if (bottom < Duration.zero) bottom = Duration.zero;
    }
    if (perMove != null && _armedSide != null) {
      perMove -= elapsed;
      if (perMove < Duration.zero) perMove = Duration.zero;
    }
    return (top: top, bottom: bottom, perMove: perMove);
  }

  void _freezeClocksIntoState() {
    if (!_anyClockEnabled) return;
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
      perMoveRemaining: live.perMove,
      isPaused: state.isPaused,
    );
    _armedAt = null;
    _armedSide = null;
  }

  void _onTick() {
    if (!_anyClockEnabled || state.isPaused) return;
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
      perMoveRemaining: live.perMove,
      isPaused: state.isPaused,
    );
    // Re-arm from now: state.topRemaining/bottomRemaining/perMoveRemaining
    // already reflect elapsed time up to this instant, so the next tick
    // must measure elapsed since *now*, not keep accumulating from the
    // original arm — otherwise each tick double-subtracts already-applied
    // elapsed time. Re-arming also resets the per-arm warning flag, so
    // re-derive it below from the just-frozen values instead.
    _armedAt = _clock.now();

    final activeTotalRemaining = state.gameState.turn == Side.top
        ? live.top
        : live.bottom;
    final totalTimedOut =
        state.config.timerEnabled && activeTotalRemaining <= Duration.zero;
    final perMoveTimedOut =
        live.perMove != null && live.perMove! <= Duration.zero;

    if (!_warnedForCurrentArm && !totalTimedOut && !perMoveTimedOut) {
      final totalWarning =
          state.config.timerEnabled &&
          activeTotalRemaining > Duration.zero &&
          activeTotalRemaining <= timerWarningThreshold;
      final perMoveWarning =
          live.perMove != null &&
          live.perMove! > Duration.zero &&
          live.perMove! <= timerWarningThreshold;
      if (totalWarning || perMoveWarning) {
        _warnedForCurrentArm = true;
        final settings = ref.read(settingsControllerProvider);
        if (settings.hapticsOn) ref.read(hapticsPortProvider).warning();
        if (settings.soundOn) ref.read(soundPortProvider).warning();
      }
    }

    if (totalTimedOut || perMoveTimedOut) {
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
