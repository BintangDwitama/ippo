import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/reminder_time.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  static const _reviewCap = 'daily_review_cap';
  static const _reminderMinutes = 'reminder_minutes';
  static const _voiceNoticeShown = 'voice_notice_shown';

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
