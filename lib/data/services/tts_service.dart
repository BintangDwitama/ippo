import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over the device's text-to-speech engine.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const String japanese = 'ja-JP';

  final FlutterTts _tts;
  bool _languageSet = false;

  /// The rate the engine was last given; null before the first speech.
  double? _rate;

  Future<bool> isJapaneseAvailable() async {
    try {
      final Object? available = await _tts.isLanguageAvailable(japanese);
      return available == true;
    } on Exception {
      return false;
    }
  }

  /// Speaks [text] in Japanese at [rate], where 0.5 is the voice's natural
  /// speed. Interrupts anything still being spoken.
  Future<void> speakJapanese(String text, {required double rate}) async {
    if (!_languageSet) {
      await _tts.setLanguage(japanese);
      _languageSet = true;
    }
    if (_rate != rate) {
      await _tts.setSpeechRate(rate);
      _rate = rate;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
