import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/item.dart';

@immutable
sealed class WordLessonUiState {
  const WordLessonUiState();
}

class WordLessonLoading extends WordLessonUiState {
  const WordLessonLoading();
}

/// No word lesson can be taken right now.
class WordLessonUnavailable extends WordLessonUiState {
  const WordLessonUnavailable();
}

/// Showing one new word with its meanings.
class WordLessonPresenting extends WordLessonUiState {
  const WordLessonPresenting({
    required this.item,
    required this.index,
    required this.total,
    required this.voiceAvailable,
  });

  final Item item;

  /// Position of this word in the lesson, from 0.
  final int index;
  final int total;

  /// Whether the phone can speak Japanese.
  final bool voiceAvailable;

  bool get isFirst => index == 0;
  bool get isLast => index == total - 1;
}

/// Asking for the meaning of one of the lesson's words.
class WordLessonCheck extends WordLessonUiState {
  const WordLessonCheck({
    required this.item,
    required this.options,
    required this.answered,
    required this.total,
  });

  final Item item;

  /// Four words; their meanings are the choices.
  final List<Item> options;

  /// Words already answered correctly.
  final int answered;
  final int total;
}

/// The learner chose the wrong meaning.
class WordLessonFeedback extends WordLessonUiState {
  const WordLessonFeedback({
    required this.item,
    required this.chosen,
    required this.voiceAvailable,
  });

  final Item item;
  final Item chosen;
  final bool voiceAvailable;
}

class WordLessonComplete extends WordLessonUiState {
  const WordLessonComplete({required this.items});

  final List<Item> items;
}
