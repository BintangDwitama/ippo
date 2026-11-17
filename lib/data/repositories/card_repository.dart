import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// Access to review cards and their schedules.
abstract interface class CardRepository {
  /// All cards, updated whenever any card changes.
  Stream<List<ReviewCard>> getCardsStream();

  Future<List<ReviewCard>> getCards();

  /// Creates the card for [itemId] and [promptType]. If it already exists,
  /// the existing card is returned unchanged.
  Future<ReviewCard> createCard({
    required int itemId,
    required PromptType promptType,
    required SchedulingState scheduling,
    required DateTime createdAt,
  });

  /// Saves the schedule and counters of an existing card.
  Future<void> updateCard(ReviewCard card);
}
