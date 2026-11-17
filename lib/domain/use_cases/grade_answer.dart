import 'package:ippo/data/repositories/card_repository.dart';
import 'package:ippo/data/repositories/review_repository.dart';
import 'package:ippo/data/repositories/unit_of_work.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/scheduling/scheduler.dart';

/// Records one answer: reschedules the card, stores the review, and
/// unlocks the typed card once the learner has earned it.
class GradeAnswer {
  GradeAnswer({
    required this._cardRepository,
    required this._reviewRepository,
    required this._unitOfWork,
    required this._scheduler,
  });

  /// Correct multiple-choice reviews in a row before typing is unlocked.
  static const int graduationStreak = 3;

  final CardRepository _cardRepository;
  final ReviewRepository _reviewRepository;
  final UnitOfWork _unitOfWork;
  final Scheduler _scheduler;

  /// Returns the card as saved after the review.
  Future<ReviewCard> call({
    required ReviewCard card,
    required bool wasCorrect,
    required DateTime now,
  }) {
    // Kana answers are plainly right or wrong, so grading is automatic.
    final rating = wasCorrect ? Rating.good : Rating.again;
    final lastReview = card.scheduling.lastReview;
    final updated = card.copyWith(
      scheduling: _scheduler.next(card.scheduling, rating, now),
      reps: card.reps + 1,
      lapses: card.lapses + (wasCorrect ? 0 : 1),
      consecutiveCorrect: wasCorrect ? card.consecutiveCorrect + 1 : 0,
    );

    return _unitOfWork.run(() async {
      await _cardRepository.updateCard(updated);
      await _reviewRepository.addReview(
        cardId: card.id,
        reviewedAt: now,
        rating: rating,
        wasCorrect: wasCorrect,
        phaseBefore: card.scheduling.phase,
        elapsedDays:
            lastReview == null ? 0 : now.difference(lastReview).inDays,
      );
      if (card.promptType == PromptType.charToSoundChoice &&
          updated.consecutiveCorrect >= graduationStreak) {
        // createCard leaves an existing typed card untouched.
        await _cardRepository.createCard(
          itemId: card.itemId,
          promptType: PromptType.charToSoundTyped,
          scheduling: _scheduler.initialState(now),
          createdAt: now,
        );
      }
      return updated;
    });
  }
}
