import 'dart:math';

import 'package:ippo/domain/models/review_card.dart';

/// Chooses and orders the cards of a review session.
class BuildReviewSession {
  const BuildReviewSession();

  /// Returns the session's cards in presentation order.
  ///
  /// Takes the most overdue of the cards due at [now], up to
  /// [remainingCap], then interleaves them so that scripts and prompt
  /// types are mixed and no kana appears twice in a row where avoidable.
  /// Cards that need audio are left out, still due, when
  /// [voiceAvailable] is false.
  List<ReviewCard> call({
    required List<ReviewCard> cards,
    required DateTime now,
    required int remainingCap,
    required bool voiceAvailable,
    required Random random,
  }) {
    if (remainingCap <= 0) return const [];
    final due = cards
        .where((card) => card.isDueAt(now))
        .where((card) => voiceAvailable || !card.promptType.needsAudio)
        .toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    final chosen = due.take(remainingCap).toList()..shuffle(random);
    return _separateSameItem(chosen);
  }

  /// Reorders so that consecutive cards belong to different items
  /// whenever another card is available.
  List<ReviewCard> _separateSameItem(List<ReviewCard> shuffled) {
    final remaining = [...shuffled];
    final leftPerItem = <int, int>{};
    for (final card in remaining) {
      leftPerItem.update(card.itemId, (n) => n + 1, ifAbsent: () => 1);
    }

    final ordered = <ReviewCard>[];
    while (remaining.isNotEmpty) {
      final lastItemId = ordered.isEmpty ? null : ordered.last.itemId;
      // Take from the item with the most cards left, so that its cards
      // are not stranded together at the end. Ties keep the shuffled order.
      var pick = -1;
      for (var i = 0; i < remaining.length; i++) {
        final itemId = remaining[i].itemId;
        if (itemId == lastItemId) continue;
        if (pick < 0 ||
            leftPerItem[itemId]! > leftPerItem[remaining[pick].itemId]!) {
          pick = i;
        }
      }
      final card = remaining.removeAt(pick < 0 ? 0 : pick);
      leftPerItem.update(card.itemId, (n) => n - 1);
      ordered.add(card);
    }
    return ordered;
  }
}
