import 'package:ippo/domain/models/japanese_voice.dart';

/// Plays the spoken sound of Japanese text.
abstract interface class SpeechRepository {
  /// Asks the phone what it can do about speaking Japanese. Asked again
  /// on every call, so a voice downloaded while the app is open is
  /// noticed.
  Future<JapaneseVoice> getJapaneseVoice();

  /// Whether anything can be spoken, by the answer [getJapaneseVoice]
  /// last gave; asks if it has not been asked yet.
  Future<bool> isJapaneseVoiceAvailable();

  /// Gets the phone's speech engine ready, so the first sound does not
  /// wait for it. Never throws.
  Future<void> prepare();

  /// Opens the phone's screen for downloading voice data. False when the
  /// phone has no such screen; the learner must then find it in the
  /// phone's settings.
  Future<bool> openVoiceDownload();

  /// Speaks [text], stopping anything already playing.
  Future<void> speak(String text);

  Future<void> stop();
}
