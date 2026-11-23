import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/japanese_voice.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';

/// What the home screen puts forward as the one thing to do next.
enum HomePrimaryAction {
  /// Cards are due: review them.
  review,

  /// Nothing is due, but new kana can be learned today.
  lesson,

  /// Nothing is due and today's kana are done, but new words can be
  /// learned.
  wordLesson,

  /// Nothing to do right now.
  rest,
}

@immutable
class HomeUiState {
  const HomeUiState({
    this.isLoading = true,
    this.goal,
    this.progress,
    this.dueCount = 0,
    this.nextLessonKana = const [],
    this.nextLessonWords = const [],
    this.streak = 0,
    this.nextDue,
    this.isReviewCapReached = false,
    this.voiceNotice,
    this.voiceDownloadUnavailable = false,
  });

  final bool isLoading;

  /// The current goal; null before the learner has set one.
  final Goal? goal;
  final GoalProgress? progress;

  /// Cards that can be reviewed right now.
  final int dueCount;

  /// The characters the next lesson introduces, in teaching order; empty
  /// when no lesson is available today.
  final List<String> nextLessonKana;

  /// The readings of the words the next word lesson introduces, in
  /// learning order; empty when no word lesson is available today.
  final List<String> nextLessonWords;
  final int streak;

  /// When the next card becomes due, if nothing is due now.
  final DateTime? nextDue;

  /// Cards are due, but today's review cap has been reached.
  final bool isReviewCapReached;

  /// The state of the Japanese voice to tell the learner about: missing
  /// or not downloaded. Null when there is nothing to say.
  final JapaneseVoice? voiceNotice;

  /// The phone could not open its voice download screen, so the notice
  /// must say where to find it.
  final bool voiceDownloadUnavailable;

  bool get showVoiceNotice => voiceNotice != null;

  bool get needsGoalSetup => !isLoading && goal == null;

  /// Kana in the next lesson; 0 when no lesson is available today.
  int get lessonSize => nextLessonKana.length;

  /// Words in the next word lesson; 0 when none is available today.
  int get wordLessonSize => nextLessonWords.length;

  /// Reviews come first, then a kana lesson, then a word lesson, then
  /// rest. Kana before words, because kana unlock words.
  HomePrimaryAction get primaryAction {
    if (dueCount > 0) return HomePrimaryAction.review;
    if (lessonSize > 0) return HomePrimaryAction.lesson;
    if (wordLessonSize > 0) return HomePrimaryAction.wordLesson;
    return HomePrimaryAction.rest;
  }
}
