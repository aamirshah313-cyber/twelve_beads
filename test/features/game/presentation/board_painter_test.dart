import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/features/game/presentation/board_layout.dart';
import 'package:twelve_beads/features/game/presentation/board_painter.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/game/engine/side.dart';

BoardLayout _layout() =>
    BoardLayout.fromGraph(BoardGraph.standard(), const Size(300, 300));

BoardVisualState _visual({
  Map<NodeId, Side> pieces = const {},
  NodeId? selectedNode,
  Set<NodeId> legalMoveTargets = const {},
  Set<NodeId> legalCaptureTargets = const {},
  Set<NodeId> forcedCaptureSources = const {},
  NodeId? lastMoveSource,
  NodeId? lastMoveDestination,
  bool highContrast = false,
  bool highQualityEffects = false,
  ColorScheme colorScheme = const ColorScheme.light(),
}) => BoardVisualState(
  graph: BoardGraph.standard(),
  layout: _layout(),
  pieces: pieces,
  selectedNode: selectedNode,
  legalMoveTargets: legalMoveTargets,
  legalCaptureTargets: legalCaptureTargets,
  forcedCaptureSources: forcedCaptureSources,
  lastMoveSource: lastMoveSource,
  lastMoveDestination: lastMoveDestination,
  colorScheme: colorScheme,
  highContrast: highContrast,
  highQualityEffects: highQualityEffects,
);

void main() {
  group('effectiveBeadColor', () {
    test('returns the plain thematic color when high contrast is off', () {
      expect(
        effectiveBeadColor(
          Side.top,
          highContrast: false,
          brightness: Brightness.light,
        ),
        topBeadColor,
      );
      expect(
        effectiveBeadColor(
          Side.bottom,
          highContrast: false,
          brightness: Brightness.light,
        ),
        bottomBeadColor,
      );
    });

    test(
      'high contrast produces a visibly different, more saturated color',
      () {
        final boosted = effectiveBeadColor(
          Side.top,
          highContrast: true,
          brightness: Brightness.light,
        );
        expect(boosted, isNot(topBeadColor));
        final baseHsl = HSLColor.fromColor(topBeadColor);
        final boostedHsl = HSLColor.fromColor(boosted);
        expect(boostedHsl.saturation, greaterThanOrEqualTo(baseHsl.saturation));
      },
    );

    test(
      'high contrast darkens on a light theme and lightens on a dark theme',
      () {
        final onLight = effectiveBeadColor(
          Side.top,
          highContrast: true,
          brightness: Brightness.light,
        );
        final onDark = effectiveBeadColor(
          Side.top,
          highContrast: true,
          brightness: Brightness.dark,
        );
        final baseLightness = HSLColor.fromColor(topBeadColor).lightness;
        expect(HSLColor.fromColor(onLight).lightness, lessThan(baseLightness));
        expect(
          HSLColor.fromColor(onDark).lightness,
          greaterThan(baseLightness),
        );
      },
    );
  });

  group('BoardPainter.shouldRepaint', () {
    test('returns false when nothing meaningful changed', () {
      final a = BoardPainter(_visual(pieces: const {'r0c0': Side.top}));
      final b = BoardPainter(_visual(pieces: const {'r0c0': Side.top}));
      expect(b.shouldRepaint(a), isFalse);
    });

    test('returns true when the pieces map differs', () {
      final a = BoardPainter(_visual(pieces: const {'r0c0': Side.top}));
      final b = BoardPainter(_visual(pieces: const {'r0c0': Side.bottom}));
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when the selected node differs', () {
      final a = BoardPainter(_visual(selectedNode: 'r0c0'));
      final b = BoardPainter(_visual(selectedNode: 'r1c1'));
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when legal target sets differ', () {
      final a = BoardPainter(_visual(legalMoveTargets: const {'r0c0'}));
      final b = BoardPainter(_visual(legalMoveTargets: const {'r0c0', 'r1c1'}));
      expect(b.shouldRepaint(a), isTrue);
    });

    test('returns true when highContrast or highQualityEffects differ', () {
      final a = BoardPainter(_visual(highContrast: false));
      final b = BoardPainter(_visual(highContrast: true));
      expect(b.shouldRepaint(a), isTrue);

      final c = BoardPainter(_visual(highQualityEffects: false));
      final d = BoardPainter(_visual(highQualityEffects: true));
      expect(d.shouldRepaint(c), isTrue);
    });
  });
}
