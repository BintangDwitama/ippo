import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// One voice the speech engine offers.
@immutable
class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    required this.needsNetwork,
    this.isInstalled = true,
    this.isLanguageDefault = false,
  });

  /// Reads a voice as the speech plugin describes it; null if it lacks a
  /// name or a locale.
  static TtsVoice? fromPlugin(Object? voice) {
    if (voice is! Map<Object?, Object?>) return null;
    final name = voice['name'];
    final locale = voice['locale'];
    if (name is! String || locale is! String) return null;
    final features = '${voice['features'] ?? ''}'.split('\t');
    return TtsVoice(
      name: name,
      locale: locale,
      needsNetwork: '${voice['network_required']}' == '1',
      isInstalled: !features.contains('notInstalled'),
      isLanguageDefault: features.contains('legacySetLanguageVoice'),
    );
  }

  final String name;
  final String locale;

  /// Whether each sound is fetched over the network.
  final bool needsNetwork;

  /// False while the voice's data still has to be downloaded.
  final bool isInstalled;

  /// Whether this is the voice the engine uses when only asked for the
  /// language.
  final bool isLanguageDefault;

  /// Whether the voice works with no network connection.
  bool get worksOffline => !needsNetwork && isInstalled;
}

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

  /// Whether a Japanese voice is downloaded, so that it works without a
  /// network. Null when the engine cannot say.
  Future<bool?> isJapaneseInstalled() async {
    try {
      final Object? installed = await _tts.isLanguageInstalled(japanese);
      return installed is bool ? installed : null;
    } on Exception {
      return null;
    }
  }

  /// The Japanese voices the engine offers; empty when it cannot say.
  Future<List<TtsVoice>> japaneseVoices() async {
    try {
      final Object? voices = await _tts.getVoices;
      if (voices is! List<Object?>) return const [];
      return [
        for (final voice in voices.map(TtsVoice.fromPlugin))
          if (voice != null && voice.locale.toLowerCase() == 'ja-jp') voice,
      ];
    } on Exception {
      return const [];
    }
  }

  /// Tells the engine to speak Japanese, with [voice] when given and
  /// otherwise with whichever voice the engine picks for the language.
  Future<void> setUpJapanese({TtsVoice? voice}) async {
    await _tts.setLanguage(japanese);
    _languageSet = true;
    if (voice != null) {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    }
  }

  /// Speaks [text] in Japanese at [rate], where 0.5 is the voice's natural
  /// speed. Interrupts anything still being spoken.
  Future<void> speakJapanese(String text, {required double rate}) async {
    if (!_languageSet) await setUpJapanese();
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
