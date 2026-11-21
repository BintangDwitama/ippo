import 'package:ippo/data/repositories/reminder_repository.dart';
import 'package:ippo/data/services/notification_service.dart';
import 'package:ippo/domain/models/reminder_time.dart';

/// [ReminderRepository] using on-device scheduled notifications.
class LocalNotificationReminderRepository implements ReminderRepository {
  LocalNotificationReminderRepository(this._notifications);

  static const int _reminderId = 1;

  final NotificationService _notifications;

  @override
  Future<bool> enableReminder(ReminderTime time) async {
    if (!await _notifications.requestPermission()) return false;
    await _schedule(time);
    return true;
  }

  @override
  Future<bool> rescheduleIfPermitted(ReminderTime time) async {
    if (!await _notifications.isPermissionGranted()) return false;
    await _schedule(time);
    return true;
  }

  Future<void> _schedule(ReminderTime time) {
    return _notifications.scheduleDaily(
      id: _reminderId,
      hour: time.hour,
      minute: time.minute,
      title: 'Time for one more step',
      body: 'Your kana reviews are waiting.',
    );
  }

  @override
  Future<void> disableReminder() => _notifications.cancel(_reminderId);
}
