import 'package:ippo/data/repositories/speech_repository.dart';
import 'package:ippo/data/services/tts_service.dart';

/// [SpeechRepository] using the device's Japanese text-to-speech voice.
class TtsSpeechRepository implements SpeechRepository {
  TtsSpeechRepository(this._tts);

  final TtsService _tts;
  bool? _available;

  @override
  Future<bool> isJapaneseVoiceAvailable() async {
    return _available ??= await _tts.isJapaneseAvailable();
  }

  @override
  Future<void> speak(String text) async {
    if (!await isJapaneseVoiceAvailable()) return;
    await _tts.speakJapanese(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
