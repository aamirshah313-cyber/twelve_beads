import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Restrained, High-visual-quality-tier-only victory celebration, per
/// 04-ui-ux-and-visual-system.md's "victory confetti only on capable tier".
/// Purely decorative and non-interactive (`IgnorePointer`) — the match-over
/// dialog's text is the authoritative result, this never gates
/// understanding it. A single short (1.6s) one-shot fall, not a persistent
/// particle system, matching this project's general "restrained, not
/// unverified-cost" approach to High-tier effects (see DECISIONS.md).
class VictoryConfetti extends StatefulWidget {
  const VictoryConfetti({super.key});

  @override
  State<VictoryConfetti> createState() => _VictoryConfettiState();
}

class _VictoryConfettiState extends State<VictoryConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  static const _colors = [
    Colors.amber,
    Colors.orange,
    Colors.green,
    Colors.lightBlue,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    // Fixed seed: a stable, restrained pattern rather than genuinely random
    // per rebuild — this is decoration, not a game-state-derived cue.
    final random = math.Random(7);
    _pieces = List.generate(28, (_) {
      return _ConfettiPiece(
        startX: random.nextDouble(),
        delay: random.nextDouble() * 0.3,
        color: _colors[random.nextInt(_colors.length)],
        size: 6 + random.nextDouble() * 6,
        wobble: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_pieces, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  final double startX;
  final double delay;
  final Color color;
  final double size;
  final double wobble;

  const _ConfettiPiece({
    required this.startX,
    required this.delay,
    required this.color,
    required this.size,
    required this.wobble,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  const _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final localProgress = ((progress - piece.delay) / (1 - piece.delay))
          .clamp(0.0, 1.0);
      if (localProgress <= 0) continue;
      final y = size.height * localProgress;
      final x =
          piece.startX * size.width +
          math.sin(piece.wobble + localProgress * 6) * 14;
      final opacity = (1 - localProgress).clamp(0.0, 1.0);
      final paint = Paint()..color = piece.color.withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: piece.size,
          height: piece.size * 1.6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
