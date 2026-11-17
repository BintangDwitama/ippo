import 'package:ippo/domain/models/reminder_time.dart';

/// Schedules the daily study reminder.
abstract interface class ReminderRepository {
  /// Asks for notification permission if needed and schedules a daily
  /// reminder at [time]. Returns false if permission was refused, in
  /// which case nothing is scheduled.
  Future<bool> enableReminder(ReminderTime time);

  Future<void> disableReminder();
}
