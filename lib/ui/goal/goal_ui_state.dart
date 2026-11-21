import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';

@immutable
class GoalUiState {
  const GoalUiState({
    this.isLoading = true,
    this.goal,
    this.progress,
    this.targetSet = SaveGoal.presetTargetSet,
    this.accuracyPercent = 90,
    this.deadlineDays = SaveGoal.presetDeadlineDays,
    this.targetCounts = const {},
    this.error,
    this.isSaved = false,
  });

  final bool isLoading;

  /// The current goal; null if the learner has never set one.
  final Goal? goal;
  final GoalProgress? progress;

  /// The values in the form.
  final GoalTargetSet targetSet;
  final int accuracyPercent;
  final int deadlineDays;

  /// How many kana each target set covers.
  final Map<GoalTargetSet, int> targetCounts;

  /// Why the last save was rejected, if it was.
  final GoalValidationError? error;

  /// The form was saved; the screen can close.
  final bool isSaved;

  /// Saving starts a new goal, not an edit of the current one.
  bool get startsNewGoal =>
      goal == null || progress?.status == GoalStatus.achieved;

  GoalUiState copyWith({
    GoalTargetSet? targetSet,
    int? accuracyPercent,
    int? deadlineDays,
    GoalValidationError? error,
    bool clearError = false,
    bool? isSaved,
  }) {
    return GoalUiState(
      isLoading: isLoading,
      goal: goal,
      progress: progress,
      targetSet: targetSet ?? this.targetSet,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      deadlineDays: deadlineDays ?? this.deadlineDays,
      targetCounts: targetCounts,
      error: clearError ? null : error ?? this.error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
