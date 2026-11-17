import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/study_calendar.dart';
import 'package:ippo/domain/use_cases/calculate_daily_quota.dart';

/// Chooses the kana for the next lesson.
class GetNextLesson {
  const GetNextLesson({
    this._calculateDailyQuota = const CalculateDailyQuota(),
  });

  static const int maxBatchSize = 5;

  final CalculateDailyQuota _calculateDailyQuota;

  /// The next batch of up to [maxBatchSize] kana to introduce, in teaching
  /// order. Empty when today's quota is used up or nothing is left.
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
              activeGoal.targetSet.includes(item.kana.script),
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

    // The quota decides whether a lesson is offered; a lesson is always a
    // full batch, so kana are taught in their natural rows of five.
    if (remainingToday <= 0) return const [];
    return candidates.take(maxBatchSize).toList();
  }
}
