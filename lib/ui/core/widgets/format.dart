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
