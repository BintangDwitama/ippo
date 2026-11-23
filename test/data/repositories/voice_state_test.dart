import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/tts_speech_repository.dart';
import 'package:ippo/data/services/tts_service.dart';
import 'package:ippo/domain/models/japanese_voice.dart';

import '../../fakes/fake_repositories.dart';

/// A speech engine whose answers the test chooses.
class _FakeTtsService implements TtsService {
  bool available = true;

  /// Null when the engine cannot say.
  bool? installed = true;
  List<TtsVoice> voices = const [];
  bool failSetUp = false;

  /// The voice asked for at each set-up; null where the choice was left
  /// to the engine.
  final List<String?> setUps = [];
  final List<String> spoken = [];
  int voiceListings = 0;

  @override
  Future<bool> isJapaneseAvailable() async => available;

  @override
  Future<bool?> isJapaneseInstalled() async => installed;

  @override
  Future<List<TtsVoice>> japaneseVoices() async {
    voiceListings++;
    return voices;
  }

  @override
  Future<void> setUpJapanese({TtsVoice? voice}) async {
    if (failSetUp) throw PlatformException(code: 'engine');
    setUps.add(voice?.name);
  }

  @override
  Future<void> speakJapanese(String text, {required double rate}) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const online = TtsVoice(
    name: 'ja-jp-x-jab-network',
    locale: 'ja-JP',
    needsNetwork: true,
  );
  const local = TtsVoice(
    name: 'ja-jp-x-jab-local',
    locale: 'ja-JP',
    needsNetwork: false,
  );
  const localDefault = TtsVoice(
    name: 'ja-JP-language',
    locale: 'ja-JP',
    needsNetwork: false,
    isLanguageDefault: true,
  );

  late _FakeTtsService tts;
  late TtsSpeechRepository speech;

  setUp(() {
    tts = _FakeTtsService();
    speech = TtsSpeechRepository(tts, FakeSettingsRepository());
  });

  group('the state of the Japanese voice', () {
    test('ready when a voice is downloaded', () async {
      expect(await speech.getJapaneseVoice(), JapaneseVoice.ready);
      expect(await speech.isJapaneseVoiceAvailable(), isTrue);
    });

    test('online only when the language is offered but not downloaded',
        () async {
      tts.installed = false;
      expect(await speech.getJapaneseVoice(), JapaneseVoice.onlineOnly);
      // It can still speak.
      expect(await speech.isJapaneseVoiceAvailable(), isTrue);
    });

    test('missing when the engine has no Japanese', () async {
      tts
        ..available = false
        ..installed = false;
      expect(await speech.getJapaneseVoice(), JapaneseVoice.missing);
      expect(await speech.isJapaneseVoiceAvailable(), isFalse);
    });

    test('an engine that cannot say is taken to be ready', () async {
      tts.installed = null;
      expect(await speech.getJapaneseVoice(), JapaneseVoice.ready);
    });

    test('is asked again each time, so a download is noticed', () async {
      tts.installed = false;
      expect(await speech.getJapaneseVoice(), JapaneseVoice.onlineOnly);

      tts.installed = true;
      expect(await speech.getJapaneseVoice(), JapaneseVoice.ready);
    });

    test('a voice installed later makes sound possible', () async {
      tts.available = false;
      await speech.getJapaneseVoice();
      await speech.speak('あ');
      expect(tts.spoken, isEmpty);

      tts.available = true;
      // Not until the phone is asked again does the app know.
      expect(await speech.isJapaneseVoiceAvailable(), isFalse);
      await speech.getJapaneseVoice();
      await speech.speak('あ');
      expect(tts.spoken, ['あ']);
    });

    test('says what each state allows', () {
      expect(JapaneseVoice.ready.canSpeak, isTrue);
      expect(JapaneseVoice.ready.needsDownload, isFalse);
      expect(JapaneseVoice.onlineOnly.canSpeak, isTrue);
      expect(JapaneseVoice.onlineOnly.needsDownload, isTrue);
      expect(JapaneseVoice.missing.canSpeak, isFalse);
      expect(JapaneseVoice.missing.needsDownload, isTrue);
    });
  });

  group('which voice is used', () {
    test('the engine keeps its own choice when that works offline', () {
      expect(
        TtsSpeechRepository.chooseVoice(const [online, local, localDefault]),
        isNull,
      );
    });

    test('a downloaded voice is asked for when the default needs the network',
        () {
      const onlineDefault = TtsVoice(
        name: 'ja-JP-language',
        locale: 'ja-JP',
        needsNetwork: true,
        isLanguageDefault: true,
      );
      expect(
        TtsSpeechRepository.chooseVoice(const [onlineDefault, online, local]),
        local,
      );
    });

    test('a default whose data is not downloaded does not count', () {
      const notDownloaded = TtsVoice(
        name: 'ja-JP-language',
        locale: 'ja-JP',
        needsNetwork: false,
        isInstalled: false,
        isLanguageDefault: true,
      );
      expect(
        TtsSpeechRepository.chooseVoice(const [notDownloaded, local]),
        local,
      );
    });

    test('with only online voices the engine decides', () {
      expect(TtsSpeechRepository.chooseVoice(const [online]), isNull);
      expect(TtsSpeechRepository.chooseVoice(const []), isNull);
    });

    test('the same voice is chosen whatever order the engine lists them', () {
      const other = TtsVoice(
        name: 'ja-jp-x-htm-local',
        locale: 'ja-JP',
        needsNetwork: false,
      );
      expect(TtsSpeechRepository.chooseVoice(const [local, other]), other);
      expect(TtsSpeechRepository.chooseVoice(const [other, local]), other);
    });

    test('reads a voice as the plugin describes it', () {
      final voice = TtsVoice.fromPlugin(const {
        'name': 'ja-JP-language',
        'locale': 'ja-JP',
        'network_required': '0',
        'features': 'networkTimeoutMs\tlegacySetLanguageVoice',
      })!;
      expect(voice.worksOffline, isTrue);
      expect(voice.isLanguageDefault, isTrue);

      final pending = TtsVoice.fromPlugin(const {
        'name': 'ja-jp-x-jab-local',
        'locale': 'ja-JP',
        'network_required': '0',
        'features': 'notInstalled',
      })!;
      expect(pending.worksOffline, isFalse);

      expect(TtsVoice.fromPlugin(const {'locale': 'ja-JP'}), isNull);
      expect(TtsVoice.fromPlugin('nonsense'), isNull);
    });
  });

  group('getting the engine ready', () {
    test('prepare sets the language and voice before any sound', () async {
      tts.voices = const [online, local];
      await speech.prepare();
      expect(tts.setUps, ['ja-jp-x-jab-local']);

      await speech.speak('あ');
      // Not set up a second time.
      expect(tts.setUps, hasLength(1));
      expect(tts.spoken, ['あ']);
    });

    test('without prepare the first sound sets the engine up', () async {
      await speech.speak('あ');
      await speech.speak('い');
      expect(tts.setUps, [null]);
      expect(tts.spoken, ['あ', 'い']);
    });

    test('prepare does nothing without a voice and never fails', () async {
      tts.available = false;
      await speech.prepare();
      expect(tts.setUps, isEmpty);

      tts
        ..available = true
        ..failSetUp = true;
      await speech.prepare();
    });

    test('a voice downloaded mid-session is used from the next sound',
        () async {
      tts
        ..installed = false
        ..voices = const [online];
      await speech.prepare();
      expect(tts.setUps, [null]);

      tts
        ..installed = true
        ..voices = const [online, local];
      await speech.getJapaneseVoice();
      await speech.speak('あ');
      expect(tts.setUps, [null, 'ja-jp-x-jab-local']);
    });
  });

  group('opening the download screen', () {
    const channel = MethodChannel(TtsSpeechRepository.setupChannelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('reports that it opened', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return true;
      });
      expect(await speech.openVoiceDownload(), isTrue);
      expect(calls, ['openVoiceDownload']);
    });

    test('reports when the phone has no such screen', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      expect(await speech.openVoiceDownload(), isFalse);
    });

    test('is false where there is no Android side, or it fails', () async {
      expect(await speech.openVoiceDownload(), isFalse);

      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'denied');
      });
      expect(await speech.openVoiceDownload(), isFalse);
    });
  });
}
