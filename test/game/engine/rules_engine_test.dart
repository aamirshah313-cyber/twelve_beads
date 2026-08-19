import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/game_state.dart';
import 'package:twelve_beads/game/engine/rules_engine.dart';
import 'package:twelve_beads/game/engine/ruleset.dart';
import 'package:twelve_beads/game/engine/side.dart';

const _optionalCaptureRuleset = Ruleset(
  id: 'test_optional_capture',
  version: 1,
  displayName: 'Test (optional capture)',
  mandatoryCapture: false,
  chainCaptureMandatory: true,
  noCaptureMoveLimitForDraw: 40,
  stalemateIsLossForPlayerToMove: true,
);

GameState _customState({
  required Map<NodeId, Side> pieces,
  required Side turn,
  Ruleset ruleset = Ruleset.classicAlquerque,
  NodeId? mustContinueCaptureFrom,
  int chainStepIndex = 0,
  int plyCount = 0,
  int pliesSinceLastCapture = 0,
}) {
  return GameState(
    graph: BoardGraph.standard(),
    pieces: Map.unmodifiable(pieces),
    turn: turn,
    ruleset: ruleset,
    phase: GamePhase.playing,
    winner: null,
    winReason: null,
    isDraw: false,
    mustContinueCaptureFrom: mustContinueCaptureFrom,
    chainStepIndex: chainStepIndex,
    plyCount: plyCount,
    pliesSinceLastCapture: pliesSinceLastCapture,
  );
}

void main() {
  group('GameState.initial()', () {
    test(
      'seeds exactly 24 pieces, 12 per side, matching StandardStartingLayout',
      () {
        final state = GameState.initial();
        expect(state.pieces.length, 24);
        expect(state.pieces.values.where((s) => s == Side.top).length, 12);
        expect(state.pieces.values.where((s) => s == Side.bottom).length, 12);
        for (final node in StandardStartingLayout.topSide) {
          expect(state.pieces[node], Side.top);
        }
        for (final node in StandardStartingLayout.bottomSide) {
          expect(state.pieces[node], Side.bottom);
        }
      },
    );

    test(
      'defaults to classic Alquerque ruleset, top to move, playing phase',
      () {
        final state = GameState.initial();
        expect(state.ruleset.id, 'classic_alquerque');
        expect(state.turn, Side.top);
        expect(state.phase, GamePhase.playing);
        expect(state.mustContinueCaptureFrom, isNull);
        expect(validateInvariants(state), isEmpty);
      },
    );
  });

  group('legalActions() at the initial position', () {
    test('only the 4 pieces adjacent to the sole empty node (center) can move, no captures', () {
      final state = GameState.initial();
      final actions = legalActions(state);

      expect(actions.whereType<CaptureAction>(), isEmpty);
      final moves = actions.whereType<MoveAction>().toSet();
      expect(moves, {
        const MoveAction(from: 'r1c1', to: 'r2c2'),
        const MoveAction(from: 'r1c2', to: 'r2c2'),
        const MoveAction(from: 'r1c3', to: 'r2c2'),
        const MoveAction(from: 'r2c1', to: 'r2c2'),
      });
    });
  });

  group('legal destinations come only from the declared graph/jump data', () {
    test('a non-adjacent move is illegal', () {
      final state = GameState.initial();
      const bogus = MoveAction(from: 'r0c0', to: 'r2c2');
      expect(isLegal(state, bogus), isFalse);
      expect(
        () => apply(state, bogus, matchId: 'm', actionSequence: 0),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('a capture over a non-adjacent or empty node is illegal', () {
      final state = _customState(pieces: {'r2c0': Side.top}, turn: Side.top);
      const bogus = CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2');
      expect(isLegal(state, bogus), isFalse); // r2c1 is empty, nothing to jump.
    });
  });

  group('mandatory capture (D-005 default)', () {
    test('suppresses simple moves once any capture is available anywhere for the side', () {
      final state = _customState(
        pieces: {
          'r2c0': Side.top,
          'r2c1': Side.bottom, // capturable: r2c0 -x-> r2c1 -> r2c2 (empty)
          'r4c4': Side.top, // has free simple moves of its own
          'r0c0': Side.bottom,
        },
        turn: Side.top,
      );

      final actions = legalActions(state);
      expect(actions, [
        const CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2'),
      ]);
    });

    test(
      'an optional-capture ruleset offers both captures and simple moves',
      () {
        final state = _customState(
          pieces: {
            'r2c0': Side.top,
            'r2c1': Side.bottom,
            'r4c4': Side.top,
            'r0c0': Side.bottom,
          },
          turn: Side.top,
          ruleset: _optionalCaptureRuleset,
        );

        final actions = legalActions(state);
        expect(
          actions,
          contains(const CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2')),
        );
        expect(actions.whereType<MoveAction>(), isNotEmpty);
      },
    );
  });

  group('capture mechanics', () {
    test('a single non-chaining capture removes exactly the jumped piece and passes the turn', () {
      final state = _customState(
        pieces: {'r2c0': Side.top, 'r2c1': Side.bottom, 'r4c4': Side.bottom},
        turn: Side.top,
      );

      final outcome = apply(
        state,
        const CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2'),
        matchId: 'm',
        actionSequence: 0,
      );

      expect(outcome.state.pieces, {'r2c2': Side.top, 'r4c4': Side.bottom});
      expect(outcome.state.turn, Side.bottom);
      expect(outcome.state.mustContinueCaptureFrom, isNull);
      expect(outcome.state.chainStepIndex, 0);
      expect(outcome.state.pliesSinceLastCapture, 0);
      expect(outcome.state.phase, GamePhase.playing);

      expect(outcome.event.actionType, 'capture');
      expect(outcome.event.actor, Side.top);
      expect(outcome.event.source, 'r2c0');
      expect(outcome.event.destination, 'r2c2');
      expect(outcome.event.capturedNodes, ['r2c1']);
      expect(outcome.event.chainStep, 0);
      expect(outcome.event.chainContinues, isFalse);
      expect(outcome.event.resultingTurn, Side.bottom);
    });

    test(
      'a chained double capture forces continuation before the turn passes',
      () {
        final state = _customState(
          pieces: {
            'r0c0': Side.top,
            'r0c1': Side.bottom,
            'r0c3': Side.bottom,
            'r4c4': Side.bottom, // inert, keeps bottom from being eliminated
          },
          turn: Side.top,
        );

        // Only one capture should be available: r0c0 -x-> r0c1 -> r0c2.
        expect(legalActions(state), [
          const CaptureAction(from: 'r0c0', over: 'r0c1', to: 'r0c2'),
        ]);

        final first = apply(
          state,
          const CaptureAction(from: 'r0c0', over: 'r0c1', to: 'r0c2'),
          matchId: 'm',
          actionSequence: 0,
        );

        expect(
          first.state.turn,
          Side.top,
          reason: 'chain forces the same side to continue',
        );
        expect(first.state.mustContinueCaptureFrom, 'r0c2');
        expect(first.state.chainStepIndex, 1);
        expect(first.event.chainStep, 0);
        expect(first.event.chainContinues, isTrue);
        expect(first.event.capturedNodes, ['r0c1']);

        // Mid-chain, legalActions is restricted to captures from the landing node only.
        expect(legalActions(first.state), [
          const CaptureAction(from: 'r0c2', over: 'r0c3', to: 'r0c4'),
        ]);

        final second = apply(
          first.state,
          const CaptureAction(from: 'r0c2', over: 'r0c3', to: 'r0c4'),
          matchId: 'm',
          actionSequence: 1,
        );

        expect(second.state.pieces, {'r0c4': Side.top, 'r4c4': Side.bottom});
        expect(
          second.state.turn,
          Side.bottom,
          reason: 'no further capture available, chain ends',
        );
        expect(second.state.mustContinueCaptureFrom, isNull);
        expect(second.state.chainStepIndex, 0);
        expect(second.event.chainStep, 1);
        expect(second.event.chainContinues, isFalse);
        expect(second.event.capturedNodes, ['r0c3']);
        expect(
          second.state.phase,
          GamePhase.playing,
          reason: 'bottom still has r4c4',
        );
      },
    );
  });

  group('terminal states', () {
    test('capturing the last opposing piece ends the match by elimination', () {
      final state = _customState(
        pieces: {'r2c0': Side.top, 'r2c1': Side.bottom},
        turn: Side.top,
      );

      final outcome = apply(
        state,
        const CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2'),
        matchId: 'm',
        actionSequence: 0,
      );

      expect(outcome.state.phase, GamePhase.finished);
      expect(outcome.state.winner, Side.top);
      expect(outcome.state.winReason, WinReason.elimination);
      expect(outcome.state.isDraw, isFalse);
      expect(
        legalActions(outcome.state),
        isEmpty,
        reason: 'terminal states admit no play action',
      );
    });

    test(
      'a player boxed in with no legal move loses (stalemate-as-loss default)',
      () {
        // Top's only piece (a corner, degree 3) is fully walled in: every
        // neighbor occupied and every jump landing blocked.
        final before = _customState(
          pieces: {
            'r0c0': Side.top,
            'r0c1': Side.bottom,
            'r1c0': Side.bottom,
            'r1c1': Side.bottom,
            'r0c2': Side.bottom,
            'r2c0': Side.bottom,
            'r3c3': Side.bottom, // will move to complete the wall at r2c2
          },
          turn: Side.bottom,
        );

        expect(
          isLegal(before, const MoveAction(from: 'r3c3', to: 'r2c2')),
          isTrue,
        );

        final outcome = apply(
          before,
          const MoveAction(from: 'r3c3', to: 'r2c2'),
          matchId: 'm',
          actionSequence: 0,
        );

        expect(outcome.state.turn, Side.top);
        expect(legalActions(outcome.state), isEmpty);
        expect(outcome.state.phase, GamePhase.finished);
        expect(outcome.state.winner, Side.bottom);
        expect(outcome.state.winReason, WinReason.noLegalMoves);
      },
    );

    test('reaching the no-capture ply limit ends the match in a draw', () {
      final state = _customState(
        pieces: {'r2c0': Side.top, 'r4c4': Side.bottom},
        turn: Side.top,
        pliesSinceLastCapture:
            Ruleset.classicAlquerque.noCaptureMoveLimitForDraw - 1,
      );

      final outcome = apply(
        state,
        const MoveAction(from: 'r2c0', to: 'r1c0'),
        matchId: 'm',
        actionSequence: 0,
      );

      expect(outcome.state.isDraw, isTrue);
      expect(outcome.state.phase, GamePhase.finished);
      expect(outcome.state.winner, isNull);
    });

    test('Resign ends the match immediately in favor of the opponent', () {
      final state = _customState(
        pieces: {'r2c0': Side.top, 'r4c4': Side.bottom},
        turn: Side.top,
      );
      final outcome = apply(
        state,
        const ResignAction(Side.top),
        matchId: 'm',
        actionSequence: 0,
      );

      expect(outcome.state.phase, GamePhase.finished);
      expect(outcome.state.winner, Side.bottom);
      expect(outcome.state.winReason, WinReason.resignation);
      expect(outcome.event.actionType, 'resign');
      expect(
        () => apply(
          outcome.state,
          const ResignAction(Side.bottom),
          matchId: 'm',
          actionSequence: 1,
        ),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('Timeout ends the match immediately in favor of the opponent', () {
      final state = _customState(
        pieces: {'r2c0': Side.top, 'r4c4': Side.bottom},
        turn: Side.top,
      );
      final outcome = apply(
        state,
        const TimeoutAction(Side.bottom),
        matchId: 'm',
        actionSequence: 0,
      );

      expect(outcome.state.phase, GamePhase.finished);
      expect(outcome.state.winner, Side.top);
      expect(outcome.state.winReason, WinReason.timeout);
    });
  });

  group('result()', () {
    test('reports ongoing for a playing state and the terminal outcome once finished', () {
      final ongoing = GameState.initial();
      expect(result(ongoing).isOver, isFalse);

      final state = _customState(
        pieces: {'r2c0': Side.top, 'r2c1': Side.bottom},
        turn: Side.top,
      );
      final outcome = apply(
        state,
        const CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2'),
        matchId: 'm',
        actionSequence: 0,
      );
      final finishedResult = result(outcome.state);
      expect(finishedResult.isOver, isTrue);
      expect(finishedResult.winner, Side.top);
      expect(finishedResult.winReason, WinReason.elimination);
    });
  });

  group('serialization round-trip', () {
    test('toJson/fromJson preserves a mid-chain state exactly', () {
      final state = _customState(
        pieces: {'r0c2': Side.top, 'r0c3': Side.bottom, 'r4c4': Side.bottom},
        turn: Side.top,
        mustContinueCaptureFrom: 'r0c2',
        chainStepIndex: 1,
        plyCount: 5,
        pliesSinceLastCapture: 0,
      );

      final restored = GameState.fromJson(state.toJson());

      expect(restored.pieces, state.pieces);
      expect(restored.turn, state.turn);
      expect(restored.ruleset.id, state.ruleset.id);
      expect(restored.phase, state.phase);
      expect(restored.mustContinueCaptureFrom, state.mustContinueCaptureFrom);
      expect(restored.chainStepIndex, state.chainStepIndex);
      expect(restored.plyCount, state.plyCount);
      expect(restored.pliesSinceLastCapture, state.pliesSinceLastCapture);
    });

    test('GameAction toJson/fromJson round-trips every action type', () {
      const actions = <GameAction>[
        MoveAction(from: 'r1c1', to: 'r2c2'),
        CaptureAction(from: 'r0c0', over: 'r0c1', to: 'r0c2'),
        ResignAction(Side.top),
        TimeoutAction(Side.bottom),
      ];
      for (final action in actions) {
        expect(GameAction.fromJson(action.toJson()), action);
      }
    });
  });

  group('deterministic replay', () {
    test('replaying the same action log from the same seed reproduces the manually-applied state', () {
      // Second action is bottom's forced reply: moving to r2c2 exposes it to
      // an immediate mandatory capture by r3c2.
      const actions = [
        MoveAction(from: 'r1c2', to: 'r2c2'),
        CaptureAction(from: 'r3c2', over: 'r2c2', to: 'r1c2'),
      ];

      var manual = GameState.initial();
      for (var i = 0; i < actions.length; i++) {
        expect(
          isLegal(manual, actions[i]),
          isTrue,
          reason: 'step $i must be legal to be a valid test fixture',
        );
        manual = apply(
          manual,
          actions[i],
          matchId: 'm',
          actionSequence: i,
        ).state;
      }

      final replayed = replay(
        ruleset: Ruleset.classicAlquerque,
        firstTurn: Side.top,
        actions: actions,
        matchId: 'm',
      );

      expect(replayed.pieces, manual.pieces);
      expect(replayed.turn, manual.turn);
      expect(replayed.phase, manual.phase);
      expect(replayed.plyCount, manual.plyCount);
    });

    test('replayWithEvents produces one faithful MoveEvent per action', () {
      const actions = [
        MoveAction(from: 'r1c2', to: 'r2c2'),
        CaptureAction(from: 'r3c2', over: 'r2c2', to: 'r1c2'),
      ];

      final replayed = replayWithEvents(
        ruleset: Ruleset.classicAlquerque,
        firstTurn: Side.top,
        actions: actions,
        matchId: 'm',
      );

      expect(replayed.events.length, 2);
      expect(replayed.events[0].actor, Side.top);
      expect(replayed.events[0].actionType, 'move');
      expect(replayed.events[0].source, 'r1c2');
      expect(replayed.events[0].destination, 'r2c2');
      expect(replayed.events[0].resultingTurn, Side.bottom);
      expect(replayed.events[0].capturedNodes, isEmpty);

      expect(replayed.events[1].actor, Side.bottom);
      expect(replayed.events[1].actionType, 'capture');
      expect(replayed.events[1].source, 'r3c2');
      expect(replayed.events[1].destination, 'r1c2');
      expect(replayed.events[1].capturedNodes, ['r2c2']);
      expect(replayed.events[1].chainContinues, isFalse);
      expect(replayed.events[1].resultingTurn, Side.top);

      for (final event in replayed.events) {
        expect(event.rulesetId, Ruleset.classicAlquerque.id);
        expect(event.rulesetVersion, Ruleset.classicAlquerque.version);
      }
    });

    test('MoveEvent data faithfully replays a chained capture (schema is presentation-safe)', () {
      final state = _customState(
        pieces: {
          'r0c0': Side.top,
          'r0c1': Side.bottom,
          'r0c3': Side.bottom,
          'r4c4': Side.bottom,
        },
        turn: Side.top,
      );
      final first = apply(
        state,
        const CaptureAction(from: 'r0c0', over: 'r0c1', to: 'r0c2'),
        matchId: 'm',
        actionSequence: 0,
      );
      final second = apply(
        first.state,
        const CaptureAction(from: 'r0c2', over: 'r0c3', to: 'r0c4'),
        matchId: 'm',
        actionSequence: 1,
      );

      final events = [first.event, second.event];
      expect(events.map((e) => e.chainStep), [0, 1]);
      expect(events.map((e) => e.chainContinues), [true, false]);
      expect(events.map((e) => e.capturedNodes.single), ['r0c1', 'r0c3']);
      expect(second.state.pieces, {'r0c4': Side.top, 'r4c4': Side.bottom});
    });
  });

  group('validateInvariants()', () {
    test('the initial state has no violations', () {
      expect(validateInvariants(GameState.initial()), isEmpty);
    });

    test('flags a piece on an undeclared node', () {
      final state = _customState(
        pieces: {'not_a_node': Side.top},
        turn: Side.top,
      );
      expect(validateInvariants(state), isNotEmpty);
    });

    test('flags a mustContinueCaptureFrom node with no available capture', () {
      final state = _customState(
        pieces: {'r2c2': Side.top},
        turn: Side.top,
        mustContinueCaptureFrom: 'r2c2',
      );
      expect(validateInvariants(state), isNotEmpty);
    });
  });
}
