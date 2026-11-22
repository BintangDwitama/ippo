import 'dart:math';

import 'package:ippo/domain/models/item.dart';

/// Builds the four choices of a multiple-choice question about a word.
/// The same choices serve both directions: shown as meanings when the
/// word is the question, as words when the meaning is.
class BuildWordChoiceOptions {
  const BuildWordChoiceOptions();

  static const int optionCount = 4;

  /// Returns [correct] and three other words, shuffled.
  ///
  /// A word is never offered as a wrong answer when it is read like
  /// [correct] or shares a meaning with it: either would make a second
  /// right answer. Among the rest, in this order of preference:
  /// words the learner knows with the same part of speech (a lone verb
  /// among nouns gives itself away, since its meaning starts with "to");
  /// other words the learner knows; words the learner can read but has
  /// not learned; any word.
  ///
  /// [alsoKnown] are words to treat as known: the words of the lesson
  /// being taken.
  List<Item> call({
    required Item correct,
    required List<Item> allItems,
    required Random random,
    List<Item> alsoKnown = const [],
  }) {
    final word = correct.word;
    final meanings = {for (final m in word.meanings) m.toLowerCase()};
    final knownIds = {for (final item in alsoKnown) item.id};
    final knownKana = {
      for (final item in allItems)
        if (item.isKana && item.isIntroduced) item.key,
    };

    final suitable = [
      for (final item in allItems)
        if (item.isWord &&
            item.id != correct.id &&
            item.word.reading != word.reading &&
            !item.word.meanings.any((m) => meanings.contains(m.toLowerCase())))
          item,
    ];
    bool isKnown(Item item) =>
        item.isIntroduced || knownIds.contains(item.id);
    bool isReadable(Item item) => item.word.kanaKeys.every(knownKana.contains);
    bool sameType(Item item) => item.word.partOfSpeech == word.partOfSpeech;

    final pools = [
      suitable.where((i) => isKnown(i) && sameType(i)),
      suitable.where((i) => isKnown(i) && !sameType(i)),
      suitable.where((i) => !isKnown(i) && isReadable(i)),
      suitable.where((i) => !isKnown(i) && !isReadable(i)),
    ];

    final wrong = <Item>[];
    for (final pool in pools) {
      if (wrong.length == optionCount - 1) break;
      final shuffled = pool.toList()..shuffle(random);
      // Two options that look or mean the same would be a trick of
      // their own.
      for (final candidate in shuffled) {
        if (wrong.length == optionCount - 1) break;
        final clashes = wrong.any(
          (chosen) =>
              chosen.word.reading == candidate.word.reading ||
              chosen.word.meaningText == candidate.word.meaningText,
        );
        if (!clashes) wrong.add(candidate);
      }
    }
    return [correct, ...wrong]..shuffle(random);
  }
}
