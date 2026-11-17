import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// Access to the history of answers.
abstract interface class ReviewRepository {
  /// All review records, oldest first, updated whenever one is added.
  Stream<List<ReviewRecord>> getReviewsStream();

  /// All review records, oldest first.
  Future<List<ReviewRecord>> getReviews();

  Future<void> addReview({
    required int cardId,
    required DateTime reviewedAt,
    required Rating rating,
    required bool wasCorrect,
    required CardPhase phaseBefore,
    required int elapsedDays,
  });
}
