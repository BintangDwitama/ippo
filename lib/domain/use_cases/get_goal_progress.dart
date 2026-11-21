import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/study_calendar.dart';
import 'package:meta/meta.dart';

/// Where the learner stands against a goal.
@immutable
class GoalProgress {
  const GoalProgress({
    required this.introducedCount,
    required this.totalCount,
    required this.accuracy,
    required this.daysRemaining,
    required this.status,
  });

  final int introducedCount;
  final int totalCount;

  /// First-attempt accuracy over the goal's kana in the last seven days,
  /// from 0 to 1; null if there were no reviews.
  final double? accuracy;

  /// Days until the deadline; 0 on the deadline day or after it.
  final int daysRemaining;

  /// The status the goal should have now.
  final GoalStatus status;
}

/// Measures progress towards a goal.
class GetGoalProgress {
  const GetGoalProgress();

  static const Duration accuracyWindow = Duration(days: 7);

  GoalProgress call({
    required Goal goal,
    required List<Item> items,
    required List<ReviewCard> cards,
    required List<ReviewRecord> reviews,
    required DateTime now,
  }) {
    final targetItems = items
        .where(
          (item) =>
              item.kind == ItemKind.kana &&
              goal.targetSet.includes(item.kana),
        )
        .toList();
    final targetItemIds = targetItems.map((item) => item.id).toSet();
    final targetCardIds = cards
        .where((card) => targetItemIds.contains(card.itemId))
        .map((card) => card.id)
        .toSet();

    final windowStart = now.subtract(accuracyWindow);
    final recent = reviews.where(
      (review) =>
          targetCardIds.contains(review.cardId) &&
          review.reviewedAt.isAfter(windowStart),
    );
    final recentCount = recent.length;
    final accuracy = recentCount == 0
        ? null
        : recent.where((review) => review.wasCorrect).length / recentCount;

    final introduced = targetItems.where((item) => item.isIntroduced).length;
    final daysLeft = StudyCalendar.daysBetween(now, goal.deadline);

    return GoalProgress(
      introducedCount: introduced,
      totalCount: targetItems.length,
      accuracy: accuracy,
      daysRemaining: daysLeft < 0 ? 0 : daysLeft,
      status: _status(
        goal: goal,
        allIntroduced:
            targetItems.isNotEmpty && introduced == targetItems.length,
        accuracy: accuracy,
        deadlinePassed: daysLeft < 0,
      ),
    );
  }

  GoalStatus _status({
    required Goal goal,
    required bool allIntroduced,
    required double? accuracy,
    required bool deadlinePassed,
  }) {
    // A goal that was achieved or missed stays that way until edited.
    if (goal.status != GoalStatus.active) return goal.status;
    if (allIntroduced &&
        accuracy != null &&
        accuracy >= goal.targetAccuracy) {
      return GoalStatus.achieved;
    }
    return deadlinePassed ? GoalStatus.missed : GoalStatus.active;
  }
}
