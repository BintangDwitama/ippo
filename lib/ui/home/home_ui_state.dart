import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';

@immutable
class HomeUiState {
  const HomeUiState({
    this.isLoading = true,
    this.goal,
    this.progress,
    this.dueCount = 0,
    this.lessonSize = 0,
    this.streak = 0,
    this.nextDue,
    this.isReviewCapReached = false,
    this.showVoiceNotice = false,
  });

  final bool isLoading;

  /// The current goal; null before the learner has set one.
  final Goal? goal;
  final GoalProgress? progress;

  /// Cards that can be reviewed right now.
  final int dueCount;

  /// Kana in the next lesson; 0 when no lesson is available today.
  final int lessonSize;
  final int streak;

  /// When the next card becomes due, if nothing is due now.
  final DateTime? nextDue;

  /// Cards are due, but today's review cap has been reached.
  final bool isReviewCapReached;

  /// Whether to tell the learner that no Japanese voice is installed.
  final bool showVoiceNotice;

  bool get needsGoalSetup => !isLoading && goal == null;
}
