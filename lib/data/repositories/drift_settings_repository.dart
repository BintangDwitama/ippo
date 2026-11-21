import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/speech_speed.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  static const _reviewCap = 'daily_review_cap';
  static const _reminderMinutes = 'reminder_minutes';
  static const _voiceNoticeShown = 'voice_notice_shown';
  static const _appearanceMode = 'appearance_mode';
  static const _lastExportAt = 'last_export_at';
  static const _speechSpeed = 'speech_speed';

  final AppDatabase _db;

  @override
  Future<int> getDailyReviewCap() async {
    final value = await _read(_reviewCap);
    return value == null
        ? SettingsRepository.defaultDailyReviewCap
        : int.parse(value);
  }

  @override
  Future<void> setDailyReviewCap(int cap) async {
    if (cap < 1) {
      throw ArgumentError.value(cap, 'cap', 'The cap must be at least 1');
    }
    await _write(_reviewCap, cap.toString());
  }

  @override
  Future<ReminderTime?> getReminderTime() async {
    final value = await _read(_reminderMinutes);
    if (value == null) return null;
    final minutes = int.parse(value);
    return ReminderTime(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  Future<void> setReminderTime(ReminderTime? time) async {
    if (time == null) {
      await (_db.delete(_db.settings)
            ..where((t) => t.name.equals(_reminderMinutes)))
          .go();
    } else {
      await _write(_reminderMinutes, (time.hour * 60 + time.minute).toString());
    }
  }

  @override
  Future<bool> isVoiceNoticeShown() async {
    return await _read(_voiceNoticeShown) == 'true';
  }

  @override
  Future<void> setVoiceNoticeShown() => _write(_voiceNoticeShown, 'true');

  @override
  Stream<AppearanceMode> getAppearanceModeStream() {
    return (_db.select(_db.settings)
          ..where((t) => t.name.equals(_appearanceMode)))
        .watchSingleOrNull()
        .map((row) => AppearanceMode.fromName(row?.value))
        .distinct();
  }

  @override
  Future<AppearanceMode> getAppearanceMode() async {
    return AppearanceMode.fromName(await _read(_appearanceMode));
  }

  @override
  Future<void> setAppearanceMode(AppearanceMode mode) {
    return _write(_appearanceMode, mode.name);
  }

  @override
  Future<DateTime?> getLastExportAt() async {
    final value = await _read(_lastExportAt);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> setLastExportAt(DateTime time) {
    return _write(_lastExportAt, time.toUtc().toIso8601String());
  }

  @override
  Future<SpeechSpeed> getSpeechSpeed() async {
    return SpeechSpeed.fromName(await _read(_speechSpeed));
  }

  @override
  Future<void> setSpeechSpeed(SpeechSpeed speed) {
    return _write(_speechSpeed, speed.name);
  }

  Future<String?> _read(String name) async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String name, String value) {
    return _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(name: name, value: value),
        );
  }
}
