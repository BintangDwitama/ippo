import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// Works out how far the learner has got with one kana.
class GetKanaStatus {
  const GetKanaStatus();

  /// A card counts as known once its memory is expected to last this long.
  static const double knownStabilityDays = 21;

  /// [cards] are the cards belonging to [item].
  KanaStatus call(Item item, Iterable<ReviewCard> cards) {
    if (!item.isIntroduced) return KanaStatus.notStarted;
    // A mark has no cards to mature; its lesson is all there is to it.
    if (item.kana.isMark) return KanaStatus.known;
    if (cards.isEmpty) return KanaStatus.learning;
    final allKnown = cards.every(
      (card) =>
          card.scheduling.phase == CardPhase.review &&
          (card.scheduling.stability ?? 0) >= knownStabilityDays,
    );
    return allKnown ? KanaStatus.known : KanaStatus.learning;
  }
}
