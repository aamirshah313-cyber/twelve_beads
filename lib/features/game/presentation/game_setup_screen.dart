import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../game/engine/side.dart';
import '../application/match_config.dart';
import 'match_screen.dart';

enum _MatchMode { twoPlayer, vsMachine }

enum _FirstTurn { random, playerOne, playerTwo }

enum _Difficulty { easy, medium, difficult }

/// Pre-game configuration screen ("New Match"). Two-player mode launches a
/// real match via [MatchScreen] against the Phase 2 engine. Vs-Machine mode
/// still reports honestly that no AI opponent exists yet — that's a later
/// phase — rather than pretending a match exists.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  final _playerOneController = TextEditingController();
  final _playerTwoController = TextEditingController();

  _MatchMode _mode = _MatchMode.twoPlayer;
  _FirstTurn _firstTurn = _FirstTurn.random;
  _Difficulty _difficulty = _Difficulty.medium;
  late int _timerMinutes;

  @override
  void initState() {
    super.initState();
    _timerMinutes = ref.read(settingsControllerProvider).timerDefaultMinutes;
  }

  @override
  void dispose() {
    _playerOneController.dispose();
    _playerTwoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameScreenTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  l10n.gameModeLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<_MatchMode>(
                  segments: [
                    ButtonSegment(
                      value: _MatchMode.twoPlayer,
                      label: Text(l10n.gameModeTwoPlayer),
                    ),
                    ButtonSegment(
                      value: _MatchMode.vsMachine,
                      label: Text(l10n.gameModeVsMachine),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      setState(() => _mode = selection.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _playerOneController,
                  decoration: InputDecoration(
                    labelText: l10n.playerOneNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_mode == _MatchMode.twoPlayer)
                  TextField(
                    controller: _playerTwoController,
                    decoration: InputDecoration(
                      labelText: l10n.playerTwoNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                if (_mode == _MatchMode.vsMachine) ...[
                  Text(
                    l10n.difficultyLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<_Difficulty>(
                    segments: [
                      ButtonSegment(
                        value: _Difficulty.easy,
                        label: Text(l10n.difficultyEasy),
                      ),
                      ButtonSegment(
                        value: _Difficulty.medium,
                        label: Text(l10n.difficultyMedium),
                      ),
                      ButtonSegment(
                        value: _Difficulty.difficult,
                        label: Text(l10n.difficultyDifficult),
                      ),
                    ],
                    selected: {_difficulty},
                    onSelectionChanged: (selection) =>
                        setState(() => _difficulty = selection.first),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.firstTurnLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<_FirstTurn>(
                  segments: [
                    ButtonSegment(
                      value: _FirstTurn.random,
                      label: Text(l10n.firstTurnRandom),
                    ),
                    ButtonSegment(
                      value: _FirstTurn.playerOne,
                      label: Text(l10n.firstTurnPlayerOne),
                    ),
                    ButtonSegment(
                      value: _FirstTurn.playerTwo,
                      label: Text(l10n.firstTurnPlayerTwo),
                    ),
                  ],
                  selected: {_firstTurn},
                  onSelectionChanged: (selection) =>
                      setState(() => _firstTurn = selection.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.timerLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownMenu<int>(
                  initialSelection: _timerMinutes,
                  onSelected: (value) =>
                      setState(() => _timerMinutes = value ?? 0),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: 0, label: l10n.timerOff),
                    const DropdownMenuEntry(value: 1, label: '1'),
                    const DropdownMenuEntry(value: 3, label: '3'),
                    const DropdownMenuEntry(value: 5, label: '5'),
                    const DropdownMenuEntry(value: 10, label: '10'),
                    const DropdownMenuEntry(value: 15, label: '15'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget + AppSpacing.md,
                    ),
                  ),
                  onPressed: () => _startMatch(context, l10n),
                  child: Text(l10n.startMatchButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startMatch(BuildContext context, AppLocalizations l10n) {
    if (_mode == _MatchMode.vsMachine) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.machineNotReadyMessage)));
      return;
    }

    final firstTurn = switch (_firstTurn) {
      _FirstTurn.playerOne => Side.top,
      _FirstTurn.playerTwo => Side.bottom,
      _FirstTurn.random => Random().nextBool() ? Side.top : Side.bottom,
    };

    final playerOneName = _playerOneController.text.trim().isEmpty
        ? l10n.firstTurnPlayerOne
        : _playerOneController.text.trim();
    final playerTwoName = _playerTwoController.text.trim().isEmpty
        ? l10n.firstTurnPlayerTwo
        : _playerTwoController.text.trim();

    final config = MatchConfig(
      playerOneName: playerOneName,
      playerTwoName: playerTwoName,
      playerOneSide: Side.top,
      firstTurn: firstTurn,
      timerMinutes: _timerMinutes,
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MatchScreen(config: config)));
  }
}
