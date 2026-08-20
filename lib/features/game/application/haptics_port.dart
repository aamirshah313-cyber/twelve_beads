import 'package:flutter/services.dart';

/// Thin seam around [HapticFeedback] so presentation-timeline haptics are
/// mockable/recordable in tests without touching platform channels.
abstract class HapticsPort {
  void selection();
  void move();
  void capture();
  void matchEnd();
  void warning();
}

class SystemHapticsPort implements HapticsPort {
  const SystemHapticsPort();

  @override
  void selection() => HapticFeedback.selectionClick();

  @override
  void move() => HapticFeedback.lightImpact();

  @override
  void capture() => HapticFeedback.mediumImpact();

  @override
  void matchEnd() => HapticFeedback.heavyImpact();

  @override
  void warning() => HapticFeedback.vibrate();
}

/// No sound assets are bundled yet (that's an asset-sourcing task, not
/// implemented in this phase) — this stub keeps the sound-cue call sites and
/// the `soundOn` setting wired up honestly, without pretending audio plays.
/// Replace with a real player once licensed sound assets are added.
abstract class SoundPort {
  void selection();
  void move();
  void capture();
  void matchEnd();
  void warning();
}

class NoopSoundPort implements SoundPort {
  const NoopSoundPort();

  @override
  void selection() {}

  @override
  void move() {}

  @override
  void capture() {}

  @override
  void matchEnd() {}

  @override
  void warning() {}
}
