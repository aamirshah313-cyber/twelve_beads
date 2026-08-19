import 'package:clock/clock.dart' as pkg_clock;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable monotonic-ish clock, per the "Inject a monotonic clock" clock
/// policy in 03-architecture-and-data.md. Using [DateTime.now] directly
/// would make timeout behavior untestable without waiting real seconds; a
/// fake implementation lets tests advance time deterministically.
abstract class GameClock {
  DateTime now();
}

/// Reads `package:clock`'s ambient clock rather than raw [DateTime.now].
/// This matters beyond testability: `flutter_test` runs every `testWidgets`
/// body inside a `fake_async` zone, which fakes the ambient `clock` package
/// clock (not raw `DateTime.now()`) to stay in lockstep with `pump()`. Using
/// [DateTime.now] directly would silently desync real elapsed-time math
/// from the fake timers driving it — this makes the two always agree,
/// automatically, in both production and any fake-async test context.
class SystemGameClock implements GameClock {
  const SystemGameClock();

  @override
  DateTime now() => pkg_clock.clock.now();
}

/// Shared by [MatchController] and [MovePresentationController] so both the
/// chess clock and the move-presentation timer can be driven by the same
/// fake clock in tests. Overridden in tests to inject a fake [GameClock];
/// production uses the real system clock.
final gameClockProvider = Provider<GameClock>((ref) => const SystemGameClock());
