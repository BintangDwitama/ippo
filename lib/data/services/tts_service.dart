import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over the device's text-to-speech engine.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const String japanese = 'ja-JP';

  final FlutterTts _tts;
  bool _configured = false;

  Future<bool> isJapaneseAvailable() async {
    try {
      final Object? available = await _tts.isLanguageAvailable(japanese);
      return available == true;
    } on Exception {
      return false;
    }
  }

  Future<void> speakJapanese(String text) async {
    if (!_configured) {
      await _tts.setLanguage(japanese);
      // Slightly slow, so single syllables are easy to hear.
      await _tts.setSpeechRate(0.4);
      _configured = true;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
