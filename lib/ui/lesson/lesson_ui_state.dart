import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/mnemonic.dart';

@immutable
sealed class LessonUiState {
  const LessonUiState();
}

class LessonLoading extends LessonUiState {
  const LessonLoading();
}

/// No lesson can be taken right now.
class LessonUnavailable extends LessonUiState {
  const LessonUnavailable();
}

/// Showing one new kana with its reading and mnemonic.
class LessonPresenting extends LessonUiState {
  const LessonPresenting({
    required this.item,
    required this.mnemonic,
    required this.index,
    required this.total,
    this.hasQuiz = true,
  });

  final Item item;
  final Mnemonic mnemonic;

  /// Position of this kana in the lesson, from 0.
  final int index;
  final int total;

  /// Whether a quiz follows the last kana. A lesson of marks has none.
  final bool hasQuiz;

  bool get isLast => index == total - 1;
}

/// Asking for the reading of one of the lesson's kana.
class LessonQuiz extends LessonUiState {
  const LessonQuiz({
    required this.item,
    required this.options,
    required this.answered,
    required this.total,
  });

  final Item item;
  final List<Item> options;

  /// Kana already answered correctly.
  final int answered;
  final int total;
}

/// The learner chose the wrong reading.
class LessonFeedback extends LessonUiState {
  const LessonFeedback({
    required this.item,
    required this.mnemonic,
    required this.chosen,
  });

  final Item item;
  final Mnemonic mnemonic;
  final Item chosen;
}

class LessonComplete extends LessonUiState {
  const LessonComplete({required this.items, this.hasReviewCards = true});

  final List<Item> items;

  /// Whether the lesson put anything into the learner's reviews. A lesson
  /// of marks does not.
  final bool hasReviewCards;
}
