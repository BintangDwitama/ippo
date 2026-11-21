import 'package:ippo/domain/models/reminder_time.dart';

/// Schedules the daily study reminder.
abstract interface class ReminderRepository {
  /// Asks for notification permission if needed and schedules a daily
  /// reminder at [time]. Returns false if permission was refused, in
  /// which case nothing is scheduled.
  Future<bool> enableReminder(ReminderTime time);

  Future<void> disableReminder();

  /// Schedules the reminder at [time] if notifications are already
  /// allowed. Never asks for permission. Returns false, scheduling
  /// nothing, if they are not allowed.
  Future<bool> rescheduleIfPermitted(ReminderTime time);
}
