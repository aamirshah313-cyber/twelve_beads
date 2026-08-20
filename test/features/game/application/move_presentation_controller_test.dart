import 'package:clock/clock.dart' as pkg_clock;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twelve_beads/core/settings/app_settings.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/core/settings/settings_repository.dart';
import 'package:twelve_beads/features/game/application/game_clock.dart';
import 'package:twelve_beads/features/game/application/haptics_port.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/move_presentation_controller.dart';
import 'package:twelve_beads/features/game/application/move_presentation_state.dart';
import 'package:twelve_beads/game/engine/move_event.dart';
import 'package:twelve_beads/game/engine/side.dart';

class _AdapterClock implements GameClock {
  _AdapterClock(this._clock);
  final pkg_clock.Clock _clock;
  @override
  DateTime now() => _clock.now();
}

class _RecordingHapticsPort implements HapticsPort {
  final calls = <String>[];
  @override
  void selection() => calls.add('selection');
  @override
  void move() => calls.add('move');
  @override
  void capture() => calls.add('capture');
  @override
  void matchEnd() => calls.add('matchEnd');
  @override
  void warning() => calls.add('warning');
}

const _config = MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Bilal',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: 0,
);

MoveEvent _moveEvent({required String source, required String destination}) =>
    MoveEvent(
      matchId: 'm',
      actionSequence: 0,
      actor: Side.top,
      actionType: 'move',
      source: source,
      destination: destination,
      capturedNodes: const [],
      chainStep: 0,
      chainContinues: false,
      resultingTurn: Side.bottom,
      rulesetId: 'classic_alquerque',
      rulesetVersion: 1,
    );

MoveEvent _captureEvent({
  required String source,
  required String over,
  required String destination,
  bool chainContinues = false,
  int chainStep = 0,
}) => MoveEvent(
  matchId: 'm',
  actionSequence: 0,
  actor: Side.top,
  actionType: 'capture',
  source: source,
  destination: destination,
  capturedNodes: [over],
  chainStep: chainStep,
  chainContinues: chainContinues,
  resultingTurn: chainContinues ? Side.top : Side.bottom,
  rulesetId: 'classic_alquerque',
  rulesetVersion: 1,
);

Future<SettingsRepository> _createSettingsRepository() async {
  SharedPreferences.setMockInitialValues({});
  return SettingsRepository.create();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a container wired with a fake clock (driven by [async]) and a
  /// recording haptics port, plus an explicit [AppSettings] override so
  /// timing is deterministic regardless of the real settings defaults.
  ({ProviderContainer container, _RecordingHapticsPort haptics}) buildHarness(
    FakeAsync async,
    SettingsRepository settingsRepository, {
    ReducedMotionPreference reducedMotion = ReducedMotionPreference.off,
    VisualQuality visualQuality = VisualQuality.standard,
    bool hapticsOn = true,
  }) {
    final haptics = _RecordingHapticsPort();
    final container = ProviderContainer(
      overrides: [
        gameClockProvider.overrideWithValue(
          _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
        ),
        hapticsPortProvider.overrideWithValue(haptics),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        deviceLanguageCodeProvider.overrideWithValue('en'),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(settingsControllerProvider.notifier)
        .setReducedMotion(reducedMotion);
    container
        .read(settingsControllerProvider.notifier)
        .setVisualQuality(visualQuality);
    container.read(settingsControllerProvider.notifier).setHapticsOn(hapticsOn);

    container.listen(
      movePresentationControllerProvider(_config),
      (_, _) {},
      fireImmediately: true,
    );
    return (container: container, haptics: haptics);
  }

  test(
    'a simple move plays source -> travel -> destination, then returns to idle',
    () async {
      final settingsRepository = await _createSettingsRepository();
      fakeAsync((async) {
        final harness = buildHarness(async, settingsRepository);
        final notifier = harness.container.read(
          movePresentationControllerProvider(_config).notifier,
        );

        notifier.enqueue({
          'r1c2': Side.top,
        }, _moveEvent(source: 'r1c2', destination: 'r2c2'));

        var state = harness.container.read(
          movePresentationControllerProvider(_config),
        );
        expect(state.isPlaying, isTrue);
        expect(state.phase, PresentationPhase.source);
        expect(harness.haptics.calls, ['move']);

        async.elapse(const Duration(milliseconds: 150)); // source highlight
        state = harness.container.read(
          movePresentationControllerProvider(_config),
        );
        expect(state.phase, PresentationPhase.travel);

        async.elapse(const Duration(milliseconds: 100));
        state = harness.container.read(
          movePresentationControllerProvider(_config),
        );
        expect(state.travelProgress, greaterThan(0));
        expect(state.travelProgress, lessThan(1));

        async.elapse(
          const Duration(seconds: 2),
        ); // finish travel + destination phase
        state = harness.container.read(
          movePresentationControllerProvider(_config),
        );
        expect(
          state.isPlaying,
          isFalse,
          reason: 'a non-capture move has no captureHighlight phase',
        );
      });
    },
  );

  test('a capture visits captureHighlight before returning to idle, with capture haptics', () async {
    final settingsRepository = await _createSettingsRepository();
    fakeAsync((async) {
      final harness = buildHarness(async, settingsRepository);
      final notifier = harness.container.read(
        movePresentationControllerProvider(_config).notifier,
      );

      notifier.enqueue({
        'r2c0': Side.top,
        'r2c1': Side.bottom,
      }, _captureEvent(source: 'r2c0', over: 'r2c1', destination: 'r2c2'));

      expect(harness.haptics.calls, ['capture']);

      async.elapse(const Duration(milliseconds: 150)); // source -> travel
      async.elapse(
        const Duration(milliseconds: 300),
      ); // travel -> captureHighlight
      var state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(state.phase, PresentationPhase.captureHighlight);

      async.elapse(const Duration(seconds: 2));
      state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(state.isPlaying, isFalse);
    });
  });

  test('a chained capture plays each jump in order, never skipping to the final state', () async {
    final settingsRepository = await _createSettingsRepository();
    fakeAsync((async) {
      final harness = buildHarness(async, settingsRepository);
      final notifier = harness.container.read(
        movePresentationControllerProvider(_config).notifier,
      );

      final first = _captureEvent(
        source: 'r0c0',
        over: 'r0c1',
        destination: 'r0c2',
        chainContinues: true,
        chainStep: 0,
      );
      final second = _captureEvent(
        source: 'r0c2',
        over: 'r0c3',
        destination: 'r0c4',
        chainStep: 1,
      );

      notifier.enqueue({'r0c0': Side.top, 'r0c1': Side.bottom}, first);
      notifier.enqueue({'r0c2': Side.top, 'r0c3': Side.bottom}, second);

      var state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(
        state.current!.event,
        first,
        reason: 'the second event must queue, not jump ahead',
      );
      expect(state.queued, [
        isA<PresentationStep>().having((s) => s.event, 'event', second),
      ]);

      // `first` (a capturing move) takes ~640ms total; elapse just past
      // that so it finishes and `second` begins, but well short of
      // `second`'s own ~640ms so it hasn't finished yet too.
      async.elapse(const Duration(milliseconds: 700));
      state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(
        state.current!.event,
        second,
        reason: 'the queued chain step starts automatically',
      );
      expect(state.queued, isEmpty);

      async.elapse(const Duration(seconds: 2));
      state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(state.isPlaying, isFalse);
    });
  });

  test('reduced motion collapses travel to effectively instant but still visits every phase', () async {
    final settingsRepository = await _createSettingsRepository();
    fakeAsync((async) {
      final harness = buildHarness(
        async,
        settingsRepository,
        reducedMotion: ReducedMotionPreference.on,
      );
      final notifier = harness.container.read(
        movePresentationControllerProvider(_config).notifier,
      );

      notifier.enqueue({
        'r2c0': Side.top,
        'r2c1': Side.bottom,
      }, _captureEvent(source: 'r2c0', over: 'r2c1', destination: 'r2c2'));

      var state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(state.phase, PresentationPhase.source);

      async.elapse(const Duration(milliseconds: 250));
      state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(
        state.phase,
        anyOf(PresentationPhase.travel, PresentationPhase.captureHighlight),
        reason: 'travel is collapsed to ~instant, not skipped',
      );

      async.elapse(const Duration(seconds: 2));
      state = harness.container.read(
        movePresentationControllerProvider(_config),
      );
      expect(state.isPlaying, isFalse);
    });
  });

  test(
    'cancelAndSnapToFinal immediately clears playback and the queue',
    () async {
      final settingsRepository = await _createSettingsRepository();
      fakeAsync((async) {
        final harness = buildHarness(async, settingsRepository);
        final notifier = harness.container.read(
          movePresentationControllerProvider(_config).notifier,
        );

        notifier.enqueue({
          'r1c2': Side.top,
        }, _moveEvent(source: 'r1c2', destination: 'r2c2'));
        notifier.enqueue({
          'r2c3': Side.bottom,
        }, _moveEvent(source: 'r2c3', destination: 'r1c2'));

        expect(
          harness.container
              .read(movePresentationControllerProvider(_config))
              .isPlaying,
          isTrue,
        );

        notifier.cancelAndSnapToFinal();

        final state = harness.container.read(
          movePresentationControllerProvider(_config),
        );
        expect(state.isPlaying, isFalse);
        expect(state.queued, isEmpty);

        // No further ticks should occur — advancing time must not resurrect
        // the cancelled step or throw from a stale timer.
        async.elapse(const Duration(seconds: 5));
        expect(
          harness.container
              .read(movePresentationControllerProvider(_config))
              .isPlaying,
          isFalse,
        );
      });
    },
  );

  test('turning the Haptics setting off silences move/capture haptics '
      '(06-localization-social-and-settings.md: sound and haptics must be '
      'independently configurable)', () async {
    final settingsRepository = await _createSettingsRepository();
    fakeAsync((async) {
      final harness = buildHarness(async, settingsRepository, hapticsOn: false);
      final notifier = harness.container.read(
        movePresentationControllerProvider(_config).notifier,
      );

      notifier.enqueue({
        'r1c2': Side.top,
      }, _moveEvent(source: 'r1c2', destination: 'r2c2'));
      async.elapse(const Duration(seconds: 2));

      notifier.enqueue({
        'r1c2': Side.top,
        'r2c2': Side.bottom,
      }, _captureEvent(source: 'r1c2', over: 'r2c2', destination: 'r3c2'));
      async.elapse(const Duration(seconds: 2));

      expect(
        harness.haptics.calls,
        isEmpty,
        reason:
            'with Haptics off in settings, no presentation-timeline '
            'event should ever call into the HapticsPort',
      );
    });
  });
}
