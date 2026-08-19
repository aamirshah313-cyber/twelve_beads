import 'package:flutter/material.dart';

import '../../../game/board/board_graph.dart';

/// Maps every [BoardGraph] node onto a square canvas, preserving the
/// graph's 5x5 aspect ratio. This is presentation-only geometry derived
/// from the validated [GridPosition] data — the board is never rendered
/// from the reference image or from ad hoc pixel guesses.
class BoardLayout {
  final Map<NodeId, Offset> positions;
  final double nodeSpacing;
  final double boardSize;
  final Offset origin;

  const BoardLayout({
    required this.positions,
    required this.nodeSpacing,
    required this.boardSize,
    required this.origin,
  });

  factory BoardLayout.fromGraph(
    BoardGraph graph,
    Size canvasSize, {
    double padding = 24,
  }) {
    final side = (canvasSize.shortestSide - padding * 2).clamp(
      0.0,
      double.infinity,
    );
    final spacing = side / (BoardGraph.gridSize - 1);
    final origin = Offset(
      (canvasSize.width - side) / 2,
      (canvasSize.height - side) / 2,
    );

    final positions = <NodeId, Offset>{
      for (final entry in graph.positions.entries)
        entry.key:
            origin +
            Offset(entry.value.col * spacing, entry.value.row * spacing),
    };

    return BoardLayout(
      positions: positions,
      nodeSpacing: spacing,
      boardSize: side,
      origin: origin,
    );
  }

  /// The node whose rendered position is within [hitRadius] of [point], if
  /// any. Used only by the invisible per-node hit-testing overlay — actual
  /// legality is always re-checked by the domain engine, never inferred
  /// from this proximity test.
  NodeId? nearestNodeWithin(Offset point, double hitRadius) {
    NodeId? closest;
    var closestDistance = double.infinity;
    for (final entry in positions.entries) {
      final distance = (entry.value - point).distance;
      if (distance <= hitRadius && distance < closestDistance) {
        closest = entry.key;
        closestDistance = distance;
      }
    }
    return closest;
  }
}
