import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_backup_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/tts_speech_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/data/services/tts_service.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/speech_speed.dart';

import '../../fakes/fake_repositories.dart';

/// Records what the speech engine is asked to do.
class _FakeTtsService implements TtsService {
  _FakeTtsService({this.available = true});

  bool available;
  int availabilityChecks = 0;

  /// Every (text, rate) spoken, in order.
  final List<(String, double)> spoken = [];
  int stops = 0;

  @override
  Future<bool> isJapaneseAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<bool?> isJapaneseInstalled() async => true;

  @override
  Future<List<TtsVoice>> japaneseVoices() async => const [];

  @override
  Future<void> setUpJapanese({TtsVoice? voice}) async {}

  @override
  Future<void> speakJapanese(String text, {required double rate}) async {
    spoken.add((text, rate));
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

void main() {
  group('SpeechSpeed', () {
    test('slows down from normal to very slow', () {
      expect(SpeechSpeed.normal.rate, 0.5);
      expect(SpeechSpeed.slow.rate, lessThan(SpeechSpeed.normal.rate));
      expect(SpeechSpeed.verySlow.rate, lessThan(SpeechSpeed.slow.rate));
      expect(SpeechSpeed.verySlow.rate, greaterThan(0));
    });

    test('the default is slow, and slower than the old fixed speed', () {
      expect(SpeechSpeed.fallback, SpeechSpeed.slow);
      expect(SpeechSpeed.fallback.rate, lessThan(0.4));
    });

    test('reads a stored name, and falls back when it is unknown', () {
      expect(SpeechSpeed.fromName('normal'), SpeechSpeed.normal);
      expect(SpeechSpeed.fromName('verySlow'), SpeechSpeed.verySlow);
      expect(SpeechSpeed.fromName(null), SpeechSpeed.slow);
      expect(SpeechSpeed.fromName('glacial'), SpeechSpeed.slow);
    });
  });

  group('stored speaking speed', () {
    late AppDatabase db;
    late DriftSettingsRepository settings;

    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = DriftSettingsRepository(db);
    });

    tearDown(() => db.close());

    test('is slow until the learner chooses', () async {
      expect(await settings.getSpeechSpeed(), SpeechSpeed.slow);
    });

    test('is stored and read back', () async {
      await settings.setSpeechSpeed(SpeechSpeed.verySlow);

      expect(await settings.getSpeechSpeed(), SpeechSpeed.verySlow);
      expect(
        await DriftSettingsRepository(db).getSpeechSpeed(),
        SpeechSpeed.verySlow,
      );
    });

    test('an unrecognised stored value reads as slow', () async {
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(name: 'speech_speed', value: 'glacial'),
          );

      expect(await settings.getSpeechSpeed(), SpeechSpeed.slow);
    });

    test('is not written to a backup', () async {
      await settings.setSpeechSpeed(SpeechSpeed.verySlow);
      final backups = DriftBackupRepository(db, settings);

      final text = const BackupCodec().encode(
        await backups.readSnapshot(DateTime.utc(2026, 11, 22)),
      );

      expect(text, isNot(contains('speech')));
      expect(text, isNot(contains('verySlow')));
    });

    test('is left alone when a backup is restored', () async {
      await settings.setSpeechSpeed(SpeechSpeed.verySlow);
      final backups = DriftBackupRepository(db, settings);

      await backups.replaceWith(
        BackupSnapshot(
          exportedAt: DateTime.utc(2026, 11, 22),
          settings: const BackupSettings(dailyReviewCap: 40),
        ),
      );

      expect(await settings.getDailyReviewCap(), 40);
      expect(await settings.getSpeechSpeed(), SpeechSpeed.verySlow);
    });
  });

  group('TtsSpeechRepository', () {
    test('speaks at the default speed when none was chosen', () async {
      final tts = _FakeTtsService();
      final speech = TtsSpeechRepository(tts, FakeSettingsRepository());

      await speech.speak('か');

      expect(tts.spoken, [('か', SpeechSpeed.slow.rate)]);
    });

    test('speaks at the stored speed', () async {
      final tts = _FakeTtsService();
      final settings = FakeSettingsRepository()
        ..speechSpeed = SpeechSpeed.verySlow;
      final speech = TtsSpeechRepository(tts, settings);

      await speech.speak('きゃ');

      expect(tts.spoken, [('きゃ', SpeechSpeed.verySlow.rate)]);
    });

    test('uses a changed speed for the very next sound', () async {
      final tts = _FakeTtsService();
      final settings = FakeSettingsRepository();
      final speech = TtsSpeechRepository(tts, settings);

      await speech.speak('あ');
      await settings.setSpeechSpeed(SpeechSpeed.normal);
      await speech.speak('あ');
      await settings.setSpeechSpeed(SpeechSpeed.verySlow);
      await speech.speak('あ');

      expect(tts.spoken.map((s) => s.$2), [
        SpeechSpeed.slow.rate,
        SpeechSpeed.normal.rate,
        SpeechSpeed.verySlow.rate,
      ]);
    });

    test('says nothing when no Japanese voice is available', () async {
      final tts = _FakeTtsService(available: false);
      final speech = TtsSpeechRepository(tts, FakeSettingsRepository());

      await speech.speak('あ');

      expect(tts.spoken, isEmpty);
    });

    test('checks for a voice once and stops on request', () async {
      final tts = _FakeTtsService();
      final speech = TtsSpeechRepository(tts, FakeSettingsRepository());

      await speech.speak('あ');
      await speech.speak('い');
      await speech.stop();

      expect(tts.availabilityChecks, 1);
      expect(tts.stops, 1);
    });
  });
}
