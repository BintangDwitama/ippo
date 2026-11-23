import 'package:flutter/services.dart';
import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/repositories/speech_repository.dart';
import 'package:ippo/data/services/tts_service.dart';
import 'package:ippo/domain/models/japanese_voice.dart';

/// [SpeechRepository] using the device's Japanese text-to-speech voice.
class TtsSpeechRepository implements SpeechRepository {
  TtsSpeechRepository(
    this._tts,
    this._settings, {
    this._setupChannel = const MethodChannel(setupChannelName),
  });

  /// The Android side that opens the engine's voice download screen (see
  /// MainActivity).
  static const String setupChannelName = 'ippo/speech_setup';
  static const String openVoiceDownloadMethod = 'openVoiceDownload';

  final TtsService _tts;

  /// Read before every sound, so a new speaking speed applies at once and
  /// no caller has to know about it.
  final SettingsRepository _settings;
  final MethodChannel _setupChannel;

  /// What the phone last said about its Japanese voice.
  JapaneseVoice? _voice;

  /// Whether the engine has been told to speak Japanese since [_voice]
  /// last changed.
  bool _isSetUp = false;

  @override
  Future<JapaneseVoice> getJapaneseVoice() async {
    final JapaneseVoice voice;
    if (!await _tts.isJapaneseAvailable()) {
      voice = JapaneseVoice.missing;
    } else {
      // An engine that cannot say whether the voice is downloaded is
      // taken at its word that it can speak: warning about a problem
      // that may not exist is worse than staying quiet.
      final installed = await _tts.isJapaneseInstalled();
      voice = installed == false ? JapaneseVoice.onlineOnly : JapaneseVoice.ready;
    }
    if (voice != _voice) {
      // A voice downloaded just now should be used from the next sound.
      _isSetUp = false;
      _voice = voice;
    }
    return voice;
  }

  @override
  Future<bool> isJapaneseVoiceAvailable() async {
    return (_voice ?? await getJapaneseVoice()).canSpeak;
  }

  @override
  Future<void> prepare() async {
    try {
      if ((await getJapaneseVoice()).canSpeak) await _setUp();
    } on Exception {
      // Sound is a convenience at this point; the first sound will try
      // again.
    }
  }

  @override
  Future<bool> openVoiceDownload() async {
    try {
      final opened =
          await _setupChannel.invokeMethod<bool>(openVoiceDownloadMethod);
      return opened ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!await isJapaneseVoiceAvailable()) return;
    if (!_isSetUp) await _setUp();
    final speed = await _settings.getSpeechSpeed();
    await _tts.speakJapanese(text, rate: speed.rate);
  }

  @override
  Future<void> stop() => _tts.stop();

  Future<void> _setUp() async {
    await _tts.setUpJapanese(
      voice: chooseVoice(await _tts.japaneseVoices()),
    );
    _isSetUp = true;
  }

  /// The voice to ask for by name, or null to leave the choice to the
  /// engine.
  ///
  /// Asked only for the language, an engine uses its default voice for
  /// it. That is left alone whenever it works offline, so a phone that
  /// already sounds right keeps its voice. Only when the default would
  /// need the network, and another voice is downloaded, is that one
  /// asked for.
  static TtsVoice? chooseVoice(List<TtsVoice> voices) {
    final offline = voices.where((voice) => voice.worksOffline).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (offline.isEmpty) return null;
    if (offline.any((voice) => voice.isLanguageDefault)) return null;
    return offline.first;
  }
}
