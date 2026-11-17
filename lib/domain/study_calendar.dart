/// Supplies the current time. Injected so tests can control it.
typedef Clock = DateTime Function();

/// Calendar-day arithmetic in the learner's local time.
abstract final class StudyCalendar {
  /// The local calendar day of [time], as a UTC midnight so that day
  /// differences are exact even across daylight-saving changes.
  static DateTime dayOf(DateTime time) {
    final local = time.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Whole calendar days from [from] to [to]; negative if [to] is earlier.
  static int daysBetween(DateTime from, DateTime to) {
    return dayOf(to).difference(dayOf(from)).inDays;
  }

  static bool isSameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);
}
