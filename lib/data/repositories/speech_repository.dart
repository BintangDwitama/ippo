/// Plays the spoken sound of Japanese text.
abstract interface class SpeechRepository {
  Future<bool> isJapaneseVoiceAvailable();

  /// Speaks [text], stopping anything already playing.
  Future<void> speak(String text);

  Future<void> stop();
}
