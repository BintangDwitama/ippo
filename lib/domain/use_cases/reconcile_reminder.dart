import 'package:ippo/data/repositories/reminder_repository.dart';
import 'package:ippo/data/repositories/settings_repository.dart';

/// Makes the scheduled reminder match the stored setting.
///
/// Needed whenever the two can have drifted apart: after data is restored
/// from a backup, and at app start, because the phone may have restored
/// the app's data without the app knowing. Never asks for permission.
class ReconcileReminder {
  const ReconcileReminder({
    required SettingsRepository settingsRepository,
    required ReminderRepository reminderRepository,
  }) : _settings = settingsRepository,
       _reminders = reminderRepository;

  final SettingsRepository _settings;
  final ReminderRepository _reminders;

  Future<void> call() async {
    final time = await _settings.getReminderTime();
    if (time == null) {
      await _reminders.disableReminder();
      return;
    }
    if (!await _reminders.rescheduleIfPermitted(time)) {
      // Notifications are not allowed here: show the reminder as off
      // instead of claiming one that cannot fire.
      await _settings.setReminderTime(null);
    }
  }
}
