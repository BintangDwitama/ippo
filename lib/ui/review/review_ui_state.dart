import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/mnemonic.dart';
import 'package:ippo/domain/models/review_card.dart';

@immutable
sealed class ReviewUiState {
  const ReviewUiState();
}

class ReviewLoading extends ReviewUiState {
  const ReviewLoading();
}

/// Nothing can be reviewed right now.
class ReviewEmpty extends ReviewUiState {
  const ReviewEmpty({this.nextDue, this.isCapReached = false});

  /// When the next card becomes due, if known.
  final DateTime? nextDue;

  /// Cards are due, but today's cap has been reached.
  final bool isCapReached;
}

class ReviewQuestion extends ReviewUiState {
  const ReviewQuestion({
    required this.item,
    required this.promptType,
    required this.options,
    required this.reviewed,
    required this.total,
    required this.isRepeat,
  });

  final Item item;
  final PromptType promptType;

  /// The four choices; empty for typed prompts. For a word card these
  /// are words, shown as meanings or as words by the prompt type.
  final List<Item> options;

  /// Cards attempted so far in this session.
  final int reviewed;
  final int total;

  /// The card was answered wrongly earlier and is back for practice.
  final bool isRepeat;
}

/// What follows an answer: after a wrong answer to a kana card, and after
/// every answer to a word card, which shows the word in full either way.
class ReviewFeedback extends ReviewUiState {
  const ReviewFeedback({
    required this.item,
    required this.promptType,
    required this.givenAnswer,
    this.mnemonic,
    this.wasCorrect = false,
    this.voiceAvailable = true,
  });

  final Item item;

  /// The kana's mnemonic; null for a word, which has none.
  final Mnemonic? mnemonic;

  final bool wasCorrect;

  /// Whether the phone can speak Japanese.
  final bool voiceAvailable;
  final PromptType promptType;

  /// What the learner answered, as shown to them.
  final String givenAnswer;
}

class ReviewSummary extends ReviewUiState {
  const ReviewSummary({required this.reviewed, required this.accuracy});

  final int reviewed;

  /// Share of cards answered correctly at the first attempt, 0 to 1.
  final double accuracy;
}
