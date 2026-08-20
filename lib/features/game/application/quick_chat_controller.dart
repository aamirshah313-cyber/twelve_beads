import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/engine/side.dart';
import 'match_config.dart';

/// Currently-displayed quick-chat bubble, if any. Idle (both fields null)
/// most of the time — a sent phrase auto-dismisses on its own timer.
class QuickChatState {
  final String? phraseId;
  final Side? side;

  const QuickChatState({this.phraseId, this.side});

  static const idle = QuickChatState();

  bool get isVisible => phraseId != null;
}

/// Drives the local-only quick-chat overlay for one match. Rate-limited by
/// construction (a new phrase can't be sent while one is still showing, so
/// sends are naturally spaced at least [displayDuration] apart) and
/// auto-dismissing, per 05-ai-and-gameplay-systems.md — this is flavor, not
/// a communication channel: there is no free text and nothing ever leaves
/// the device.
class QuickChatController extends Notifier<QuickChatState> {
  QuickChatController(this.config);

  final MatchConfig config;

  static const displayDuration = Duration(seconds: 3);

  Timer? _dismissTimer;

  @override
  QuickChatState build() {
    ref.onDispose(() => _dismissTimer?.cancel());
    return QuickChatState.idle;
  }

  bool get canSend => !state.isVisible;

  /// Shows [phraseId] attributed to [side], if the rate limit allows it.
  /// Returns whether it was actually sent.
  bool send(String phraseId, Side side) {
    if (!canSend) return false;
    state = QuickChatState(phraseId: phraseId, side: side);
    _dismissTimer = Timer(displayDuration, () {
      state = QuickChatState.idle;
    });
    return true;
  }
}

final quickChatControllerProvider = NotifierProvider.family
    .autoDispose<QuickChatController, QuickChatState, MatchConfig>(
      QuickChatController.new,
    );
