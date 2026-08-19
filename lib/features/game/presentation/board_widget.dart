import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../game/board/board_graph.dart';
import '../../../game/engine/game_action.dart';
import '../application/match_config.dart';
import '../application/match_controller.dart';
import 'board_layout.dart';
import 'board_painter.dart';

/// Procedurally-drawn, accessibly hit-testable game board. Rendering comes
/// from [BoardPainter] against the validated [BoardGraph]; every node also
/// gets an invisible, individually semantic, 48dp-minimum tap target laid
/// out at the same computed position, so TalkBack can navigate node by node
/// and every legal-action check still goes through the domain engine via
/// [MatchController.onNodeTapped].
class BoardWidget extends ConsumerWidget {
  const BoardWidget({super.key, required this.config});

  final MatchConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(matchControllerProvider(config));
    final controller = ref.read(matchControllerProvider(config).notifier);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = BoardLayout.fromGraph(matchState.gameState.graph, size);

        final legalFromSelected = matchState.selectedNode == null
            ? const <GameAction>[]
            : matchState.legalActions
                  .where((a) => _sourceOf(a) == matchState.selectedNode)
                  .toList();
        final legalMoveTargets = <NodeId>{
          for (final a in legalFromSelected)
            if (a is MoveAction) a.to,
        };
        final legalCaptureTargets = <NodeId>{
          for (final a in legalFromSelected)
            if (a is CaptureAction) a.to,
        };
        final forcedCaptureSources = matchState.forcedCaptureActive
            ? <NodeId>{
                for (final a in matchState.legalActions)
                  if (a is CaptureAction) a.from,
              }
            : const <NodeId>{};

        final visual = BoardVisualState(
          graph: matchState.gameState.graph,
          layout: layout,
          pieces: matchState.gameState.pieces,
          selectedNode: matchState.selectedNode,
          legalMoveTargets: legalMoveTargets,
          legalCaptureTargets: legalCaptureTargets,
          forcedCaptureSources: forcedCaptureSources,
          lastMoveSource: matchState.lastMoveSource,
          lastMoveDestination: matchState.lastMoveDestination,
          colorScheme: colorScheme,
        );

        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: BoardPainter(visual))),
            for (final entry in layout.positions.entries)
              _NodeHitTarget(
                node: entry.key,
                center: entry.value,
                config: config,
                matchState: matchState,
                legalMoveTargets: legalMoveTargets,
                legalCaptureTargets: legalCaptureTargets,
                l10n: l10n,
                onTap: () => controller.onNodeTapped(entry.key),
              ),
          ],
        );
      },
    );
  }
}

NodeId? _sourceOf(GameAction action) => switch (action) {
  MoveAction(:final from) => from,
  CaptureAction(:final from) => from,
  ResignAction() || TimeoutAction() => null,
};

class _NodeHitTarget extends StatelessWidget {
  const _NodeHitTarget({
    required this.node,
    required this.center,
    required this.config,
    required this.matchState,
    required this.legalMoveTargets,
    required this.legalCaptureTargets,
    required this.l10n,
    required this.onTap,
  });

  final NodeId node;
  final Offset center;
  final MatchConfig config;
  final MatchUiState matchState;
  final Set<NodeId> legalMoveTargets;
  final Set<NodeId> legalCaptureTargets;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = AppSpacing.minTouchTarget;
    final side = matchState.gameState.pieces[node];

    final buffer = StringBuffer(
      side == null
          ? l10n.pieceNodeLabelEmpty
          : l10n.pieceNodeLabelOwn(config.nameForSide(side)),
    );
    if (matchState.selectedNode == node) buffer.write(l10n.pieceNodeSelected);
    if (legalMoveTargets.contains(node)) buffer.write(l10n.pieceNodeLegalMove);
    if (legalCaptureTargets.contains(node)) {
      buffer.write(l10n.pieceNodeLegalCapture);
    }
    if (node == matchState.lastMoveSource ||
        node == matchState.lastMoveDestination) {
      buffer.write(l10n.pieceNodeLastMove);
    }

    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: buffer.toString(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
