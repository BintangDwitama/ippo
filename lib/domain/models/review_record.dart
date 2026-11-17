import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:meta/meta.dart';

/// The permanent record of one answer to one card.
@immutable
class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.rating,
    required this.wasCorrect,
    required this.phaseBefore,
    required this.elapsedDays,
  });

  final int id;
  final int cardId;

  /// Always UTC.
  final DateTime reviewedAt;
  final Rating rating;
  final bool wasCorrect;

  /// The card's phase before this review.
  final CardPhase phaseBefore;

  /// Whole days since the card's previous review; 0 for a first review.
  final int elapsedDays;
}
