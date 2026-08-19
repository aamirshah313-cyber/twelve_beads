/// Injectable monotonic-ish clock, per the "Inject a monotonic clock" clock
/// policy in 03-architecture-and-data.md. Using [DateTime.now] directly
/// would make timeout behavior untestable without waiting real seconds; a
/// fake implementation lets tests advance time deterministically.
abstract class GameClock {
  DateTime now();
}

class SystemGameClock implements GameClock {
  const SystemGameClock();

  @override
  DateTime now() => DateTime.now();
}
