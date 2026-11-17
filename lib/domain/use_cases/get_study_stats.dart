import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/study_calendar.dart';

/// Day-based figures derived from the study history.
class GetStudyStats {
  const GetStudyStats();

  /// Consecutive days of study up to today.
  ///
  /// A day counts if at least one card was reviewed or one lesson was
  /// completed. A streak that reached yesterday is still alive today;
  /// it grows once the learner studies today.
  int streak({
    required List<Item> items,
    required List<ReviewRecord> reviews,
    required DateTime now,
  }) {
    final studyDays = {
      for (final review in reviews) StudyCalendar.dayOf(review.reviewedAt),
      for (final item in items)
        if (item.introducedAt != null) StudyCalendar.dayOf(item.introducedAt!),
    };
    final today = StudyCalendar.dayOf(now);
    var day = studyDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var count = 0;
    while (studyDays.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Number of graded reviews done today.
  int reviewsToday({
    required List<ReviewRecord> reviews,
    required DateTime now,
  }) {
    return reviews
        .where((review) => StudyCalendar.isSameDay(review.reviewedAt, now))
        .length;
  }

  /// How many more reviews today's cap allows.
  int remainingReviewCap({
    required int dailyCap,
    required List<ReviewRecord> reviews,
    required DateTime now,
  }) {
    final left = dailyCap - reviewsToday(reviews: reviews, now: now);
    return left < 0 ? 0 : left;
  }
}
