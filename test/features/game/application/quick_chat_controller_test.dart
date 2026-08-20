import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/quick_chat_controller.dart';
import 'package:twelve_beads/features/game/application/quick_chat_phrases.dart';
import 'package:twelve_beads/game/engine/side.dart';

const _config = MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Bilal',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: 0,
);

void main() {
  test('a sent phrase appears immediately and auto-dismisses after the '
      'display duration', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(
        quickChatControllerProvider(_config),
        (_, _) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        quickChatControllerProvider(_config).notifier,
      );
      final sent = notifier.send(QuickChatPhraseIds.goodMove, Side.top);
      expect(sent, isTrue);

      final state = container.read(quickChatControllerProvider(_config));
      expect(state.isVisible, isTrue);
      expect(state.phraseId, QuickChatPhraseIds.goodMove);
      expect(state.side, Side.top);

      async.elapse(QuickChatController.displayDuration);
      expect(
        container.read(quickChatControllerProvider(_config)).isVisible,
        isFalse,
      );
    });
  });

  test('rate limit blocks a second send while one is already showing', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(
        quickChatControllerProvider(_config),
        (_, _) {},
        fireImmediately: true,
      );
      final notifier = container.read(
        quickChatControllerProvider(_config).notifier,
      );

      expect(notifier.send(QuickChatPhraseIds.goodMove, Side.top), isTrue);
      expect(notifier.canSend, isFalse);

      async.elapse(const Duration(seconds: 1));
      final blocked = notifier.send(QuickChatPhraseIds.yourTurn, Side.top);
      expect(blocked, isFalse);
      // The first phrase is still showing — a blocked send must not
      // replace it.
      expect(
        container.read(quickChatControllerProvider(_config)).phraseId,
        QuickChatPhraseIds.goodMove,
      );
    });
  });

  test('sending again is allowed once the previous phrase has dismissed', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(
        quickChatControllerProvider(_config),
        (_, _) {},
        fireImmediately: true,
      );
      final notifier = container.read(
        quickChatControllerProvider(_config).notifier,
      );

      expect(notifier.send(QuickChatPhraseIds.goodMove, Side.top), isTrue);
      async.elapse(QuickChatController.displayDuration);
      expect(notifier.canSend, isTrue);
      expect(notifier.send(QuickChatPhraseIds.wellPlayed, Side.bottom), isTrue);

      final state = container.read(quickChatControllerProvider(_config));
      expect(state.phraseId, QuickChatPhraseIds.wellPlayed);
      expect(state.side, Side.bottom);
    });
  });
}
