import 'dart:math';

import 'package:ippo/domain/models/item.dart';

/// Builds the four options of a multiple-choice kana question.
class BuildChoiceOptions {
  const BuildChoiceOptions();

  static const int optionCount = 4;

  /// Returns [correct] plus three wrong kana from the same script with a
  /// different reading, in random order.
  ///
  /// Wrong options are kana the learner has met: those in [preferred]
  /// (for example the current lesson) and those already introduced. Among
  /// them, the ones easiest to confuse with [correct] come first: its
  /// voiced or unvoiced partners, then kana that look like it, then kana
  /// of its row, then any other. If the learner has met too few, the
  /// nearest kana in teaching order fill the gap.
  List<Item> call({
    required Item correct,
    required List<Item> allItems,
    required Random random,
    List<Item> preferred = const [],
  }) {
    final answer = correct.kana;
    final preferredIds = preferred.map((item) => item.id).toSet();
    final sameScript = allItems.where(
      (item) =>
          item.kind == ItemKind.kana &&
          item.id != correct.id &&
          item.kana.script == answer.script &&
          item.kana.romaji != answer.romaji,
    );

    final tiers = List.generate(_tierCount, (_) => <Item>[]);
    final unfamiliar = <Item>[];
    for (final item in sameScript) {
      if (item.isIntroduced || preferredIds.contains(item.id)) {
        tiers[_tierOf(item.kana, answer)].add(item);
      } else {
        unfamiliar.add(item);
      }
    }
    for (final tier in tiers) {
      tier.shuffle(random);
    }
    unfamiliar.sort(
      (a, b) => (a.sortOrder - correct.sortOrder).abs().compareTo(
        (b.sortOrder - correct.sortOrder).abs(),
      ),
    );

    final wrong = [
      for (final tier in tiers) ...tier,
      ...unfamiliar,
    ].take(optionCount - 1);
    return [correct, ...wrong]..shuffle(random);
  }

  static const int _tierCount = 4;

  /// How confusable [other] is with [answer]; lower is more confusable.
  static int _tierOf(KanaPayload other, KanaPayload answer) {
    if (other.family == answer.family) return 0;
    if (answer.lookalikes.contains(other.character) ||
        other.lookalikes.contains(answer.character)) {
      return 1;
    }
    if (answer.row.isNotEmpty && other.row == answer.row) return 2;
    return 3;
  }
}
