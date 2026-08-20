import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../game/ai/difficulty.dart' as ai;
import '../../../game/engine/side.dart';
import '../application/match_config.dart';
import 'match_screen.dart';

enum _MatchMode { twoPlayer, vsMachine }

enum _FirstTurn { random, playerOne, playerTwo }

enum _Difficulty { easy, medium, difficult }

extension on _Difficulty {
  ai.Difficulty toEngineDifficulty() => switch (this) {
    _Difficulty.easy => ai.Difficulty.easy,
    _Difficulty.medium => ai.Difficulty.medium,
    _Difficulty.difficult => ai.Difficulty.difficult,
  };
}

/// Sentinel dropdown value meaning "let me type a number" — never a real
/// timer value (both total minutes and per-move seconds are always >= 0).
const _customTimerSentinel = -1;

/// Pre-game configuration screen ("New Match"). Both two-player and
/// vs-Machine modes launch a real match via [MatchScreen]; vs-Machine wires
/// in [MatchConfig.machineSide]/[MatchConfig.difficulty], which
/// `MachineController` (Phase 5) picks up to drive the offline opponent.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  final _playerOneController = TextEditingController();
  final _playerTwoController = TextEditingController();
  final _customTimerMinutesController = TextEditingController();
  final _customPerMoveSecondsController = TextEditingController();

  _MatchMode _mode = _MatchMode.twoPlayer;
  _FirstTurn _firstTurn = _FirstTurn.random;
  _Difficulty _difficulty = _Difficulty.medium;
  late int _timerMinutes;
  bool _timerIsCustom = false;
  int _perMoveSeconds = 0;
  bool _perMoveIsCustom = false;

  static const _timerPresetMinutes = [0, 1, 3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _timerMinutes = ref.read(settingsControllerProvider).timerDefaultMinutes;
    if (!_timerPresetMinutes.contains(_timerMinutes)) {
      _timerIsCustom = true;
      _customTimerMinutesController.text = '$_timerMinutes';
    }
  }

  @override
  void dispose() {
    _playerOneController.dispose();
    _playerTwoController.dispose();
    _customTimerMinutesController.dispose();
    _customPerMoveSecondsController.dispose();
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
                  initialSelection: _timerIsCustom
                      ? _customTimerSentinel
                      : _timerMinutes,
                  onSelected: (value) => setState(() {
                    if (value == _customTimerSentinel) {
                      _timerIsCustom = true;
                      final parsed = int.tryParse(
                        _customTimerMinutesController.text,
                      );
                      _timerMinutes = parsed ?? 20;
                      if (_customTimerMinutesController.text.isEmpty) {
                        _customTimerMinutesController.text = '$_timerMinutes';
                      }
                    } else {
                      _timerIsCustom = false;
                      _timerMinutes = value ?? 0;
                    }
                  }),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: 0, label: l10n.timerOff),
                    const DropdownMenuEntry(value: 1, label: '1'),
                    const DropdownMenuEntry(value: 3, label: '3'),
                    const DropdownMenuEntry(value: 5, label: '5'),
                    const DropdownMenuEntry(value: 10, label: '10'),
                    const DropdownMenuEntry(value: 15, label: '15'),
                    DropdownMenuEntry(
                      value: _customTimerSentinel,
                      label: l10n.timerCustom,
                    ),
                  ],
                ),
                if (_timerIsCustom) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _customTimerMinutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.timerCustomMinutesLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      final parsed = int.tryParse(text);
                      if (parsed != null && parsed > 0) {
                        _timerMinutes = parsed;
                      }
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.perMoveTimerLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownMenu<int>(
                  initialSelection: _perMoveIsCustom
                      ? _customTimerSentinel
                      : _perMoveSeconds,
                  onSelected: (value) => setState(() {
                    if (value == _customTimerSentinel) {
                      _perMoveIsCustom = true;
                      final parsed = int.tryParse(
                        _customPerMoveSecondsController.text,
                      );
                      _perMoveSeconds = parsed ?? 90;
                      if (_customPerMoveSecondsController.text.isEmpty) {
                        _customPerMoveSecondsController.text =
                            '$_perMoveSeconds';
                      }
                    } else {
                      _perMoveIsCustom = false;
                      _perMoveSeconds = value ?? 0;
                    }
                  }),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: 0, label: l10n.timerOff),
                    const DropdownMenuEntry(value: 15, label: '15'),
                    const DropdownMenuEntry(value: 30, label: '30'),
                    const DropdownMenuEntry(value: 45, label: '45'),
                    const DropdownMenuEntry(value: 60, label: '60'),
                    DropdownMenuEntry(
                      value: _customTimerSentinel,
                      label: l10n.timerCustom,
                    ),
                  ],
                ),
                if (_perMoveIsCustom) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _customPerMoveSecondsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.timerCustomSecondsLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      final parsed = int.tryParse(text);
                      if (parsed != null && parsed > 0) {
                        _perMoveSeconds = parsed;
                      }
                    },
                  ),
                ],
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
    final firstTurn = switch (_firstTurn) {
      _FirstTurn.playerOne => Side.top,
      _FirstTurn.playerTwo => Side.bottom,
      _FirstTurn.random => Random().nextBool() ? Side.top : Side.bottom,
    };

    final playerOneName = _playerOneController.text.trim().isEmpty
        ? l10n.firstTurnPlayerOne
        : _playerOneController.text.trim();
    final playerTwoName = _mode == _MatchMode.vsMachine
        ? l10n.machineOpponentName
        : (_playerTwoController.text.trim().isEmpty
              ? l10n.firstTurnPlayerTwo
              : _playerTwoController.text.trim());

    final config = MatchConfig(
      playerOneName: playerOneName,
      playerTwoName: playerTwoName,
      playerOneSide: Side.top,
      firstTurn: firstTurn,
      timerMinutes: _timerMinutes,
      perMoveSeconds: _perMoveSeconds,
      machineSide: _mode == _MatchMode.vsMachine ? Side.bottom : null,
      difficulty: _difficulty.toEngineDifficulty(),
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MatchScreen(config: config)));
  }
}
