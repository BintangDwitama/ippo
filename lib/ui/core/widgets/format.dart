/// Describes how long until [time], for example "in 10 min".
String formatTimeUntil(DateTime time, DateTime now) {
  final wait = time.difference(now);
  if (wait.inMinutes < 1) return 'in less than a minute';
  if (wait.inMinutes < 60) return 'in ${wait.inMinutes} min';
  if (wait.inHours < 24) {
    return wait.inHours == 1 ? 'in 1 hour' : 'in ${wait.inHours} hours';
  }
  return wait.inDays == 1 ? 'in 1 day' : 'in ${wait.inDays} days';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A date and time in the learner's local time, for example
/// "21 Nov 2026, 09:15".
String formatDateTime(DateTime time) {
  final local = time.toLocal();
  final minutes = local.minute.toString().padLeft(2, '0');
  final hours = local.hour.toString().padLeft(2, '0');
  return '${local.day} ${_months[local.month - 1]} ${local.year}, '
      '$hours:$minutes';
}
