import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/engine/side.dart';
import '../application/match_config.dart';
import '../application/match_controller.dart';
import 'board_painter.dart';
import 'board_widget.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key, required this.config});

  final MatchConfig config;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen>
    with WidgetsBindingObserver {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Clock policy: the game clock pauses while the app is inactive and
    // requires an explicit Resume tap — it never grants unearned elapsed
    // time in the background.
    if (state != AppLifecycleState.resumed) {
      ref.read(matchControllerProvider(widget.config).notifier).pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = matchControllerProvider(widget.config);
    final matchState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen(provider, (previous, next) {
      if (next.gameState.phase == GamePhase.finished && !_dialogShown) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showMatchOverDialog(context, next, l10n, controller);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchScreenTitle),
        actions: [
          IconButton(
            icon: Icon(
              matchState.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
            tooltip: matchState.isPaused ? l10n.resumeButton : l10n.pauseButton,
            onPressed: matchState.gameState.phase != GamePhase.playing
                ? null
                : () => matchState.isPaused
                      ? controller.resume()
                      : controller.pause(),
          ),
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: l10n.undoButton,
            onPressed: matchState.canUndo ? controller.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.restartButton,
            onPressed: () => _confirmRestart(context, controller, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.flag_rounded),
            tooltip: l10n.resignButton,
            onPressed: matchState.gameState.phase != GamePhase.playing
                ? null
                : () => _confirmResign(context, controller, matchState, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: l10n.navHowToPlay,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.rules),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                return isLandscape
                    ? _LandscapeMatchLayout(
                        config: widget.config,
                        state: matchState,
                      )
                    : _PortraitMatchLayout(
                        config: widget.config,
                        state: matchState,
                      );
              },
            ),
            if (matchState.isPaused)
              _PausedOverlay(l10n: l10n, onResume: controller.resume),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestart(
    BuildContext context,
    MatchController controller,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.restartConfirmTitle),
        content: Text(l10n.restartConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.restartButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _dialogShown = false;
      controller.restart();
    }
  }

  Future<void> _confirmResign(
    BuildContext context,
    MatchController controller,
    MatchUiState matchState,
    AppLocalizations l10n,
  ) async {
    final resigningSide = matchState.gameState.turn;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resignConfirmTitle),
        content: Text(
          l10n.resignConfirmBody(matchState.config.nameForSide(resigningSide)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.resignConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.resign(resigningSide);
    }
  }

  void _showMatchOverDialog(
    BuildContext context,
    MatchUiState matchState,
    AppLocalizations l10n,
    MatchController controller,
  ) {
    final gameState = matchState.gameState;
    final winner = gameState.winner;
    final loser = winner?.opponent;

    final title = gameState.isDraw
        ? l10n.matchOverDrawTitle
        : l10n.matchOverWinnerTitle(matchState.config.nameForSide(winner!));

    final reason = switch (gameState.winReason) {
      WinReason.elimination => l10n.matchOverReasonElimination,
      WinReason.noLegalMoves => l10n.matchOverReasonNoLegalMoves(
        matchState.config.nameForSide(loser!),
      ),
      WinReason.resignation => l10n.matchOverReasonResignation(
        matchState.config.nameForSide(loser!),
      ),
      WinReason.timeout => l10n.matchOverReasonTimeout(
        matchState.config.nameForSide(loser!),
      ),
      null => l10n.matchOverReasonNoCaptureLimit,
    };

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context)
                  .popUntil((route) => route.settings.name == AppRoutes.home);
            },
            child: Text(l10n.matchOverHomeButton),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _dialogShown = false;
              controller.restart();
            },
            child: Text(l10n.matchOverNewMatchButton),
          ),
        ],
      ),
    );
  }
}

class _PortraitMatchLayout extends StatelessWidget {
  const _PortraitMatchLayout({required this.config, required this.state});

  final MatchConfig config;
  final MatchUiState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TurnBanner(config: config, state: state),
        _PlayerRail(config: config, state: state, side: Side.top),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: BoardWidget(config: config),
              ),
            ),
          ),
        ),
        _PlayerRail(config: config, state: state, side: Side.bottom),
      ],
    );
  }
}

class _LandscapeMatchLayout extends StatelessWidget {
  const _LandscapeMatchLayout({required this.config, required this.state});

  final MatchConfig config;
  final MatchUiState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PlayerRail(
          config: config,
          state: state,
          side: Side.top,
          axis: Axis.vertical,
        ),
        Expanded(
          child: Column(
            children: [
              _TurnBanner(config: config, state: state),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: BoardWidget(config: config),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _PlayerRail(
          config: config,
          state: state,
          side: Side.bottom,
          axis: Axis.vertical,
        ),
      ],
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.config, required this.state});

  final MatchConfig config;
  final MatchUiState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = config.nameForSide(state.gameState.turn);

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(l10n.turnBanner(name), style: textTheme.titleLarge),
            if (state.forcedCaptureActive)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.forcedCaptureBanner,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRail extends StatelessWidget {
  const _PlayerRail({
    required this.config,
    required this.state,
    required this.side,
    this.axis = Axis.horizontal,
  });

  final MatchConfig config;
  final MatchUiState state;
  final Side side;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isActive =
        state.gameState.turn == side &&
        state.gameState.phase == GamePhase.playing;
    final remaining = side == Side.top
        ? state.topRemaining
        : state.bottomRemaining;
    final beadColor = side == Side.top ? topBeadColor : bottomBeadColor;

    final children = <Widget>[
      CircleAvatar(radius: 10, backgroundColor: beadColor),
      const SizedBox(width: AppSpacing.sm, height: AppSpacing.sm),
      Text(
        config.nameForSide(side),
        style: isActive
            ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : textTheme.titleMedium,
      ),
      if (state.config.timerEnabled) ...[
        const SizedBox(width: AppSpacing.md, height: AppSpacing.xs),
        Text(_formatDuration(remaining), style: textTheme.bodyMedium),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: axis == Axis.horizontal
          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: children)
          : Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.l10n, required this.onResume});

  final AppLocalizations l10n;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.pausedOverlayTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.pausedOverlayBody),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: onResume,
                    child: Text(l10n.resumeButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
