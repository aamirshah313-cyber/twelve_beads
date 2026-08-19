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

/// The bead color actually used to paint the board. Under the high-contrast
/// setting, the same thematic hue is boosted in saturation and pushed away
/// from mid-lightness (darker on a light theme, lighter on a dark one) so
/// beads read clearly against the board background — otherwise
/// `AppSettings.highContrast` had no visible effect on the board's most
/// important elements (Phase 7 fix; the theme-level contrast boost already
/// applied to `ColorScheme.fromSeed` only reached the background/edges,
/// which read `colorScheme` directly, not the hardcoded bead colors).
Color effectiveBeadColor(
  Side side, {
  required bool highContrast,
  required Brightness brightness,
}) {
  final base = side == Side.top ? topBeadColor : bottomBeadColor;
  if (!highContrast) return base;

  final hsl = HSLColor.fromColor(base);
  final saturated = hsl.withSaturation((hsl.saturation + 0.25).clamp(0.0, 1.0));
  final targetLightness = brightness == Brightness.dark
      ? (saturated.lightness + 0.18).clamp(0.0, 1.0)
      : (saturated.lightness - 0.18).clamp(0.0, 1.0);
  return saturated.withLightness(targetLightness).toColor();
}

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
  final bool highContrast;

  // Opponent-move presentation timeline overlay (Phase 4). All optional:
  // null/empty when no move is currently animating.
  final NodeId? presentationSourceNode;
  final NodeId? presentationDestinationNode;
  final NodeId? presentationCapturedNode;
  final Side? animatingBeadSide;
  final Offset? animatingBeadPosition;
  final bool showTrail;

  /// High visual-quality tier only (and never under reduced motion): adds a
  /// single restrained soft-glow behind the captured-piece marker. This is
  /// deliberately minimal — one extra blurred circle, no particle system —
  /// per 04-ui-ux-and-visual-system.md's "High may add restrained particles
  /// only after profiling": a real profiling setup doesn't exist in this
  /// project, so High stays intentionally conservative rather than
  /// unverified-expensive. See docs/spec/DECISIONS.md.
  final bool highQualityEffects;

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
    this.highContrast = false,
    this.highQualityEffects = false,
    this.presentationSourceNode,
    this.presentationDestinationNode,
    this.presentationCapturedNode,
    this.animatingBeadSide,
    this.animatingBeadPosition,
    this.showTrail = false,
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
    _paintPresentationHighlights(canvas);
    _paintPresentationTrail(canvas);
    _paintPresentationBead(canvas);
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
        ..color = effectiveBeadColor(
          side,
          highContrast: visual.highContrast,
          brightness: visual.colorScheme.brightness,
        );
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

  /// Source/destination/captured-piece cues for the currently-playing
  /// presentation step. Deliberately a different shape (double ring /
  /// cross-out) than the local player's own selection ring and the forced-
  /// capture dashed ring, so an opponent move is never confused with the
  /// viewer's own turn state — a "non-colour cue" per
  /// 04-ui-ux-and-visual-system.md.
  void _paintPresentationHighlights(Canvas canvas) {
    final sourcePaint = Paint()
      ..color = visual.colorScheme.secondary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final source = visual.presentationSourceNode;
    if (source != null) {
      final center = visual.layout.positions[source];
      if (center != null) {
        canvas.drawCircle(
          center,
          visual.layout.nodeSpacing * 0.36,
          sourcePaint,
        );
        canvas.drawCircle(
          center,
          visual.layout.nodeSpacing * 0.44,
          sourcePaint,
        );
      }
    }

    final destination = visual.presentationDestinationNode;
    if (destination != null) {
      final center = visual.layout.positions[destination];
      if (center != null) {
        final destPaint = Paint()
          ..color = visual.colorScheme.secondary
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, visual.layout.nodeSpacing * 0.4, destPaint);
      }
    }

    final captured = visual.presentationCapturedNode;
    if (captured != null) {
      final center = visual.layout.positions[captured];
      if (center != null) {
        if (visual.highQualityEffects) {
          final glowPaint = Paint()
            ..color = visual.colorScheme.error.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(
            center,
            visual.layout.nodeSpacing * 0.34,
            glowPaint,
          );
        }
        final crossPaint = Paint()
          ..color = visual.colorScheme.error
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final r = visual.layout.nodeSpacing * 0.3;
        canvas.drawLine(
          Offset(center.dx - r, center.dy - r),
          Offset(center.dx + r, center.dy + r),
          crossPaint,
        );
        canvas.drawLine(
          Offset(center.dx + r, center.dy - r),
          Offset(center.dx - r, center.dy + r),
          crossPaint,
        );
      }
    }
  }

  /// Lightweight fading trail from the source node to the bead's current
  /// animated position — Standard/High quality only (Low and reduced-motion
  /// skip this, per the adaptive quality tiers).
  void _paintPresentationTrail(Canvas canvas) {
    if (!visual.showTrail) return;
    final source = visual.presentationSourceNode;
    final position = visual.animatingBeadPosition;
    if (source == null || position == null) return;
    final from = visual.layout.positions[source];
    if (from == null) return;

    final paint = Paint()
      ..color = visual.colorScheme.secondary.withValues(alpha: 0.35)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, position, paint);
  }

  /// The bead being animated along the (already-validated) graph edge
  /// between source and destination. Drawn identically to a resting piece
  /// of the same side so it never "teleports": it is the same shape the
  /// static piece will resume once the step finishes.
  void _paintPresentationBead(Canvas canvas) {
    final position = visual.animatingBeadPosition;
    final side = visual.animatingBeadSide;
    if (position == null || side == null) return;

    final pieceRadius = visual.layout.nodeSpacing * 0.32;
    final fillPaint = Paint()
      ..color = effectiveBeadColor(
        side,
        highContrast: visual.highContrast,
        brightness: visual.colorScheme.brightness,
      );
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(position, pieceRadius, fillPaint);
    canvas.drawCircle(position, pieceRadius, borderPaint);
    if (side == Side.bottom) {
      final holePaint = Paint()
        ..color = visual.colorScheme.surfaceContainerHigh;
      canvas.drawCircle(position, pieceRadius * 0.42, holePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    final a = oldDelegate.visual;
    final b = visual;
    if (identical(a, b)) return false;
    // `layout`/`graph` are deliberately not compared: a resize is already
    // repainted independently of this delegate check (RenderCustomPaint
    // repaints on a box size change regardless of shouldRepaint), and
    // `graph` never changes mid-match.
    return a.selectedNode != b.selectedNode ||
        a.lastMoveSource != b.lastMoveSource ||
        a.lastMoveDestination != b.lastMoveDestination ||
        a.colorScheme != b.colorScheme ||
        a.highContrast != b.highContrast ||
        a.highQualityEffects != b.highQualityEffects ||
        a.presentationSourceNode != b.presentationSourceNode ||
        a.presentationDestinationNode != b.presentationDestinationNode ||
        a.presentationCapturedNode != b.presentationCapturedNode ||
        a.animatingBeadSide != b.animatingBeadSide ||
        a.animatingBeadPosition != b.animatingBeadPosition ||
        a.showTrail != b.showTrail ||
        !_mapEquals(a.pieces, b.pieces) ||
        !_setEquals(a.legalMoveTargets, b.legalMoveTargets) ||
        !_setEquals(a.legalCaptureTargets, b.legalCaptureTargets) ||
        !_setEquals(a.forcedCaptureSources, b.forcedCaptureSources);
  }
}

bool _mapEquals(Map<NodeId, Side> a, Map<NodeId, Side> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _setEquals(Set<NodeId> a, Set<NodeId> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
