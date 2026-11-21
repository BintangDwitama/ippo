/// How fast kana are spoken.
enum SpeechSpeed {
  /// The voice's natural speed.
  normal(0.5),

  /// Slowed enough to hear a single kana clearly. The default.
  slow(0.3),

  verySlow(0.2);

  const SpeechSpeed(this.rate);

  /// The rate given to the device voice, where 0.5 is its natural speed.
  final double rate;

  /// What a learner who has not chosen gets.
  static const SpeechSpeed fallback = SpeechSpeed.slow;

  /// The speed stored as [name]; [fallback] if it is missing or not
  /// recognised.
  static SpeechSpeed fromName(String? name) {
    for (final speed in values) {
      if (speed.name == name) return speed;
    }
    return fallback;
  }
}
