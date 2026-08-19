import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../game/board/board_graph.dart';
import '../../../game/engine/side.dart';
import 'board_layout.dart';

/// Thematic bead colors, echoing the reference image's orange/green sides.
/// Shape also differs by side (solid vs. ring-punched) so the distinction
/// never depends on color alone.
const topBeadColor = Color(0xFFE07A2C);
const bottomBeadColor = Color(0xFF3F9D52);

/// Everything the board painter needs to draw one frame. Built fresh from
/// [MatchUiState] on every rebuild — the painter itself holds no state and
/// never mutates or infers game rules.
class BoardVisualState {
  final BoardGraph graph;
  final BoardLayout layout;
  final Map<NodeId, Side> pieces;
  final NodeId? selectedNode;
  final Set<NodeId> legalMoveTargets;
  final Set<NodeId> legalCaptureTargets;
  final Set<NodeId> forcedCaptureSources;
  final NodeId? lastMoveSource;
  final NodeId? lastMoveDestination;
  final ColorScheme colorScheme;

  const BoardVisualState({
    required this.graph,
    required this.layout,
    required this.pieces,
    required this.selectedNode,
    required this.legalMoveTargets,
    required this.legalCaptureTargets,
    required this.forcedCaptureSources,
    required this.lastMoveSource,
    required this.lastMoveDestination,
    required this.colorScheme,
  });
}

class BoardPainter extends CustomPainter {
  final BoardVisualState visual;

  const BoardPainter(this.visual);

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintEdges(canvas);
    _paintLastMoveMarkers(canvas);
    _paintForcedCaptureRings(canvas);
    _paintNodesAndPieces(canvas);
    _paintSelection(canvas);
    _paintLegalTargets(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    final paint = Paint()..color = visual.colorScheme.surfaceContainerHigh;
    canvas.drawRRect(rect, paint);
  }

  void _paintEdges(Canvas canvas) {
    final paint = Paint()
      ..color = visual.colorScheme.outlineVariant
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final drawn = <String>{};
    visual.graph.edges.forEach((node, neighbors) {
      final from = visual.layout.positions[node];
      if (from == null) return;
      for (final neighbor in neighbors) {
        final key = ([node, neighbor]..sort()).join('|');
        if (!drawn.add(key)) continue;
        final to = visual.layout.positions[neighbor];
        if (to == null) continue;
        canvas.drawLine(from, to, paint);
      }
    });
  }

  void _paintNodesAndPieces(Canvas canvas) {
    final nodeRadius = visual.layout.nodeSpacing * 0.08;
    final pieceRadius = visual.layout.nodeSpacing * 0.32;

    final dotPaint = Paint()..color = visual.colorScheme.outline;

    for (final entry in visual.layout.positions.entries) {
      final node = entry.key;
      final center = entry.value;
      final side = visual.pieces[node];

      if (side == null) {
        canvas.drawCircle(center, nodeRadius, dotPaint);
        continue;
      }

      final fillPaint = Paint()
        ..color = side == Side.top ? topBeadColor : bottomBeadColor;
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, pieceRadius, fillPaint);
      canvas.drawCircle(center, pieceRadius, borderPaint);

      if (side == Side.bottom) {
        // Shape differentiator so side never depends on color alone: bottom
        // beads are "ring-punched", top beads stay solid.
        final holePaint = Paint()
          ..color = visual.colorScheme.surfaceContainerHigh;
        canvas.drawCircle(center, pieceRadius * 0.42, holePaint);
      }
    }
  }

  void _paintSelection(Canvas canvas) {
    final selected = visual.selectedNode;
    if (selected == null) return;
    final center = visual.layout.positions[selected];
    if (center == null) return;

    final ringPaint = Paint()
      ..color = visual.colorScheme.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, visual.layout.nodeSpacing * 0.4, ringPaint);
  }

  void _paintLegalTargets(Canvas canvas) {
    final movePaint = Paint()
      ..color = visual.colorScheme.primary.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final node in visual.legalMoveTargets) {
      final center = visual.layout.positions[node];
      if (center == null) continue;
      canvas.drawCircle(center, visual.layout.nodeSpacing * 0.22, movePaint);
    }

    // Capture targets get a diamond in addition to a ring, so "you can
    // capture here" never depends on color alone.
    final capturePaint = Paint()
      ..color = visual.colorScheme.error
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final node in visual.legalCaptureTargets) {
      final center = visual.layout.positions[node];
      if (center == null) continue;
      final r = visual.layout.nodeSpacing * 0.26;
      canvas.drawCircle(center, r, capturePaint);
      final diamond = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r, center.dy)
        ..close();
      canvas.drawPath(diamond, capturePaint);
    }
  }

  void _paintForcedCaptureRings(Canvas canvas) {
    if (visual.forcedCaptureSources.isEmpty) return;
    final paint = Paint()
      ..color = visual.colorScheme.tertiary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final node in visual.forcedCaptureSources) {
      final center = visual.layout.positions[node];
      if (center == null) continue;
      // A dashed-looking ring (short arcs) reads as distinct from the solid
      // selection ring without relying on color.
      const dashCount = 10;
      final radius = visual.layout.nodeSpacing * 0.38;
      for (var i = 0; i < dashCount; i++) {
        final start = (2 * math.pi / dashCount) * i;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          math.pi / dashCount,
          false,
          paint,
        );
      }
    }
  }

  void _paintLastMoveMarkers(Canvas canvas) {
    final paint = Paint()
      ..color = visual.colorScheme.secondary.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final node in [visual.lastMoveSource, visual.lastMoveDestination]) {
      if (node == null) continue;
      final center = visual.layout.positions[node];
      if (center == null) continue;
      canvas.drawCircle(center, visual.layout.nodeSpacing * 0.44, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
