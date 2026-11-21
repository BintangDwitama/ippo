import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/repositories/speech_repository.dart';
import 'package:ippo/data/services/tts_service.dart';

/// [SpeechRepository] using the device's Japanese text-to-speech voice.
class TtsSpeechRepository implements SpeechRepository {
  TtsSpeechRepository(this._tts, this._settings);

  final TtsService _tts;

  /// Read before every sound, so a new speaking speed applies at once and
  /// no caller has to know about it.
  final SettingsRepository _settings;
  bool? _available;

  @override
  Future<bool> isJapaneseVoiceAvailable() async {
    return _available ??= await _tts.isJapaneseAvailable();
  }

  @override
  Future<void> speak(String text) async {
    if (!await isJapaneseVoiceAvailable()) return;
    final speed = await _settings.getSpeechSpeed();
    await _tts.speakJapanese(text, rate: speed.rate);
  }

  @override
  Future<void> stop() => _tts.stop();
}
