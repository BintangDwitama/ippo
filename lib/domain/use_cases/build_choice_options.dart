import 'dart:math';

import 'package:ippo/domain/models/item.dart';

/// Builds the four options of a multiple-choice kana question.
class BuildChoiceOptions {
  const BuildChoiceOptions();

  static const int optionCount = 4;

  /// Returns [correct] plus three wrong kana from the same script, in
  /// random order.
  ///
  /// Wrong options prefer kana the learner has met: those in [preferred]
  /// (for example the current lesson) and those already introduced. If
  /// there are too few, the nearest kana in teaching order fill the gap.
  List<Item> call({
    required Item correct,
    required List<Item> allItems,
    required Random random,
    List<Item> preferred = const [],
  }) {
    final preferredIds = preferred.map((item) => item.id).toSet();
    final sameScript = allItems.where(
      (item) =>
          item.kind == ItemKind.kana &&
          item.id != correct.id &&
          item.kana.script == correct.kana.script &&
          item.kana.romaji != correct.kana.romaji,
    );

    final familiar = sameScript
        .where((item) => item.isIntroduced || preferredIds.contains(item.id))
        .toList()
      ..shuffle(random);
    final unfamiliar = sameScript
        .where((item) => !item.isIntroduced && !preferredIds.contains(item.id))
        .toList()
      ..sort(
        (a, b) => (a.sortOrder - correct.sortOrder)
            .abs()
            .compareTo((b.sortOrder - correct.sortOrder).abs()),
      );

    final wrong = [...familiar, ...unfamiliar].take(optionCount - 1);
    return [correct, ...wrong]..shuffle(random);
  }
}
