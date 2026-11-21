import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/study_calendar.dart';
import 'package:ippo/domain/use_cases/calculate_daily_quota.dart';

/// Chooses the kana for the next lesson.
class GetNextLesson {
  const GetNextLesson({
    this._calculateDailyQuota = const CalculateDailyQuota(),
  });

  /// The most kana one lesson introduces.
  static const int maxBatchSize = 6;

  /// Lesson size for kana whose row is unknown.
  static const int _unknownRowBatchSize = 5;

  final CalculateDailyQuota _calculateDailyQuota;

  /// The next lesson: whole rows of kana in teaching order, up to
  /// [maxBatchSize] kana, never mixing scripts or groups. Empty when
  /// today's quota is used up or nothing is left.
  ///
  /// With an active [goal], lessons cover the goal's kana and the quota
  /// comes from its deadline; otherwise all kana at a default pace.
  List<Item> call({
    required List<Item> items,
    required Goal? goal,
    required DateTime now,
  }) {
    final activeGoal = goal != null && goal.status == GoalStatus.active
        ? goal
        : null;
    final kana = items.where((item) => item.kind == ItemKind.kana).where(
          (item) =>
              activeGoal == null ||
              activeGoal.targetSet.includes(item.kana),
        );
    final candidates = kana.where((item) => !item.isIntroduced).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final introducedToday = kana
        .where(
          (item) =>
              item.introducedAt != null &&
              StudyCalendar.isSameDay(item.introducedAt!, now),
        )
        .length;

    final int remainingToday;
    if (activeGoal == null) {
      final left = CalculateDailyQuota.defaultQuota - introducedToday;
      remainingToday = left < 0 ? 0 : left;
    } else {
      remainingToday = _calculateDailyQuota.remainingToday(
        notIntroduced: candidates.length,
        introducedToday: introducedToday,
        daysRemaining: StudyCalendar.daysBetween(now, activeGoal.deadline),
      );
    }

    // The quota decides whether a lesson is offered, not its size: a
    // lesson is always whole rows, so kana are taught as they belong.
    if (remainingToday <= 0) return const [];
    return _cutLesson(candidates);
  }

  /// Takes what is left of the first row, then following rows of the same
  /// script and group for as long as the lesson stays within the limit.
  List<Item> _cutLesson(List<Item> candidates) {
    if (candidates.isEmpty) return const [];
    final first = candidates.first.kana;
    if (first.row.isEmpty) {
      return candidates.take(_unknownRowBatchSize).toList();
    }

    final rows = <List<Item>>[];
    for (final item in candidates) {
      final kana = item.kana;
      if (kana.script != first.script || kana.group != first.group) break;
      if (rows.isNotEmpty && rows.last.first.kana.row == kana.row) {
        rows.last.add(item);
      } else {
        rows.add([item]);
      }
    }

    final lesson = [...rows.first];
    for (final row in rows.skip(1)) {
      if (lesson.length + row.length > maxBatchSize) break;
      lesson.addAll(row);
    }
    return lesson;
  }
}
