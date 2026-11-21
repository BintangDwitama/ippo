import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/reminder_time.dart';

/// Access to the learner's preferences.
abstract interface class SettingsRepository {
  static const int defaultDailyReviewCap = 100;

  Future<int> getDailyReviewCap();

  /// Throws [ArgumentError] if [cap] is less than 1.
  Future<void> setDailyReviewCap(int cap);

  /// The reminder time, or null when the reminder is off.
  Future<ReminderTime?> getReminderTime();

  Future<void> setReminderTime(ReminderTime? time);

  /// Whether the "install a Japanese voice" notice has been shown.
  Future<bool> isVoiceNoticeShown();

  Future<void> setVoiceNoticeShown();

  /// The chosen appearance now and after every change.
  Stream<AppearanceMode> getAppearanceModeStream();

  /// [AppearanceMode.automatic] until the learner chooses.
  Future<AppearanceMode> getAppearanceMode();

  Future<void> setAppearanceMode(AppearanceMode mode);

  /// When this phone last exported a backup; null if it never has.
  Future<DateTime?> getLastExportAt();

  Future<void> setLastExportAt(DateTime time);
}
