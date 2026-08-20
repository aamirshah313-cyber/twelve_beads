import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../game/board/board_graph.dart';
import '../../../game/engine/move_event.dart';
import '../../../game/engine/side.dart';
import 'game_clock.dart';
import 'haptics_port.dart';
import 'match_config.dart';
import 'move_presentation_state.dart';

final hapticsPortProvider = Provider<HapticsPort>(
  (ref) => const SystemHapticsPort(),
);
final soundPortProvider = Provider<SoundPort>((ref) => const NoopSoundPort());

class _Timing {
  final Duration sourceHighlight;
  final Duration travel;
  final Duration captureHighlight;
  final Duration destinationHighlight;

  const _Timing({
    required this.sourceHighlight,
    required this.travel,
    required this.captureHighlight,
    required this.destinationHighlight,
  });

  // Matches the 120-220ms eased-slide guidance in
  // 04-ui-ux-and-visual-system.md.
  static const standard = _Timing(
    sourceHighlight: Duration(milliseconds: 150),
    travel: Duration(milliseconds: 190),
    captureHighlight: Duration(milliseconds: 150),
    destinationHighlight: Duration(milliseconds: 150),
  );

  // Low quality: "crisp source/destination and instant or very short
  // travel", no blur/particles.
  static const low = _Timing(
    sourceHighlight: Duration(milliseconds: 120),
    travel: Duration(milliseconds: 40),
    captureHighlight: Duration(milliseconds: 120),
    destinationHighlight: Duration(milliseconds: 120),
  );

  // Reduced motion: travel is collapsed to effectively instant, but every
  // discrete cue still holds long enough to be perceived without relying on
  // animated movement.
  static const reducedMotion = _Timing(
    sourceHighlight: Duration(milliseconds: 220),
    travel: Duration(milliseconds: 1),
    captureHighlight: Duration(milliseconds: 220),
    destinationHighlight: Duration(milliseconds: 220),
  );
}

bool resolveReducedMotion(ReducedMotionPreference preference) =>
    switch (preference) {
      ReducedMotionPreference.on => true,
      ReducedMotionPreference.off => false,
      ReducedMotionPreference.system =>
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations,
    };

/// Presentation-only move timeline. Consumes accepted, immutable
/// [MoveEvent]s handed to it by [MatchController] via [enqueue] and
/// serializes them into visual steps (source highlight, travel, capture
/// highlight, destination highlight) — one queued event at a time, so a
/// capture chain is always played jump by jump, never collapsed into the
/// final board state. It never mutates [GameState], decides legality, or
/// drives the (future) AI; it owns only playback timing and cancellation.
class MovePresentationController extends Notifier<MovePresentationState> {
  MovePresentationController(this.config);

  final MatchConfig config;

  Timer? _timer;
  DateTime? _phaseStartedAt;

  GameClock get _clock => ref.read(gameClockProvider);
  HapticsPort get _haptics => ref.read(hapticsPortProvider);
  SoundPort get _sound => ref.read(soundPortProvider);

  @override
  MovePresentationState build() {
    ref.onDispose(() => _timer?.cancel());
    return MovePresentationState.idle;
  }

  /// Queues [event] (with the piece map exactly as it was before it was
  /// applied) for playback. Starts playing immediately if nothing else is
  /// currently animating, otherwise plays after the current queue drains —
  /// this is what keeps a chained capture visually sequential.
  void enqueue(Map<NodeId, Side> piecesBefore, MoveEvent event) {
    final step = PresentationStep(piecesBefore: piecesBefore, event: event);
    if (state.current == null) {
      _beginStep(step);
    } else {
      state = MovePresentationState(
        current: state.current,
        queued: [...state.queued, step],
        phase: state.phase,
        travelProgress: state.travelProgress,
      );
    }
  }

  /// Immediately stops any playback and drops the queue. The board must
  /// fall back to rendering the authoritative [MatchController] state with
  /// no overlay once this returns — used by pause, restart, resign, and app
  /// backgrounding so a match action never leaves a stuck or misleading
  /// animation on screen.
  void cancelAndSnapToFinal() {
    _timer?.cancel();
    _timer = null;
    _phaseStartedAt = null;
    state = MovePresentationState.idle;
  }

  void _beginStep(PresentationStep step) {
    final settings = ref.read(settingsControllerProvider);
    if (step.event.capturedNodes.isNotEmpty) {
      if (settings.hapticsOn) _haptics.capture();
      if (settings.soundOn) _sound.capture();
    } else {
      if (settings.hapticsOn) _haptics.move();
      if (settings.soundOn) _sound.move();
    }
    state = MovePresentationState(
      current: step,
      queued: state.queued,
      phase: PresentationPhase.source,
      travelProgress: 0,
    );
    _enterPhase(PresentationPhase.source);
  }

  void _enterPhase(PresentationPhase phase) {
    _timer?.cancel();
    _phaseStartedAt = _clock.now();
    state = MovePresentationState(
      current: state.current,
      queued: state.queued,
      phase: phase,
      travelProgress: 0,
    );

    final duration = _durationFor(phase);
    if (phase == PresentationPhase.travel) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _onTravelFrame(duration),
      );
    } else {
      _timer = Timer(duration, _advance);
    }
  }

  void _onTravelFrame(Duration total) {
    final startedAt = _phaseStartedAt;
    if (startedAt == null) return;
    final elapsedMicros = _clock.now().difference(startedAt).inMicroseconds;
    final progress = total.inMicroseconds <= 0
        ? 1.0
        : (elapsedMicros / total.inMicroseconds).clamp(0.0, 1.0);

    state = MovePresentationState(
      current: state.current,
      queued: state.queued,
      phase: state.phase,
      travelProgress: progress,
    );

    if (progress >= 1.0) {
      _timer?.cancel();
      _advance();
    }
  }

  void _advance() {
    final step = state.current;
    if (step == null) return;
    switch (state.phase) {
      case PresentationPhase.source:
        _enterPhase(PresentationPhase.travel);
      case PresentationPhase.travel:
        if (step.event.capturedNodes.isNotEmpty) {
          _enterPhase(PresentationPhase.captureHighlight);
        } else {
          _enterPhase(PresentationPhase.destination);
        }
      case PresentationPhase.captureHighlight:
        _enterPhase(PresentationPhase.destination);
      case PresentationPhase.destination:
        _finishStep();
    }
  }

  void _finishStep() {
    final queued = state.queued;
    if (queued.isEmpty) {
      state = MovePresentationState.idle;
    } else {
      final next = queued.first;
      state = MovePresentationState(
        current: null,
        queued: queued.sublist(1),
        phase: PresentationPhase.source,
        travelProgress: 0,
      );
      _beginStep(next);
    }
  }

  Duration _durationFor(PresentationPhase phase) {
    final settings = ref.read(settingsControllerProvider);
    final timing = resolveReducedMotion(settings.reducedMotion)
        ? _Timing.reducedMotion
        : (settings.visualQuality == VisualQuality.low
              ? _Timing.low
              : _Timing.standard);
    return switch (phase) {
      PresentationPhase.source => timing.sourceHighlight,
      PresentationPhase.travel => timing.travel,
      PresentationPhase.captureHighlight => timing.captureHighlight,
      PresentationPhase.destination => timing.destinationHighlight,
    };
  }
}

final movePresentationControllerProvider = NotifierProvider.family
    .autoDispose<
      MovePresentationController,
      MovePresentationState,
      MatchConfig
    >(MovePresentationController.new);
