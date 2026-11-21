import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/goal/goal_ui_state.dart';

class GoalViewModel extends ViewModel {
  GoalViewModel(this._deps) {
    unawaited(_load());
  }

  final AppDependencies _deps;

  GoalUiState _uiState = const GoalUiState();
  GoalUiState get uiState => _uiState;

  Future<void> _load() async {
    final goal = await _deps.goalRepository.getCurrentGoal();
    final items = await _deps.itemRepository.getItems();
    final kana = [
      for (final item in items)
        if (item.kind == ItemKind.kana) item.kana,
    ];
    final targetCounts = {
      for (final target in GoalTargetSet.values)
        target: kana.where(target.includes).length,
    };
    if (goal == null) {
      _setState(GoalUiState(isLoading: false, targetCounts: targetCounts));
      return;
    }
    final progress = _deps.getGoalProgress(
      goal: goal,
      items: items,
      cards: await _deps.cardRepository.getCards(),
      reviews: await _deps.reviewRepository.getReviews(),
      now: _deps.clock(),
    );
    final achieved = progress.status == GoalStatus.achieved;
    _setState(
      GoalUiState(
        isLoading: false,
        goal: goal,
        progress: progress,
        // After an achieved goal, suggest the next step of the path.
        targetSet: achieved
            ? goal.targetSet.next ?? goal.targetSet
            : goal.targetSet,
        targetCounts: targetCounts,
        accuracyPercent: (goal.targetAccuracy * 100).round(),
        deadlineDays: achieved
            ? SaveGoal.presetDeadlineDays
            : SaveGoal.deadlineDaysOf(goal),
      ),
    );
  }

  void setTargetSet(GoalTargetSet targetSet) {
    _setState(_uiState.copyWith(targetSet: targetSet, clearError: true));
  }

  void setAccuracyPercent(int percent) {
    _setState(_uiState.copyWith(accuracyPercent: percent, clearError: true));
  }

  void setDeadlineDays(int days) {
    _setState(_uiState.copyWith(deadlineDays: days, clearError: true));
  }

  /// Saves the form: a new goal if there is none or the last one was
  /// achieved, otherwise an edit of the current goal.
  Future<void> save() async {
    final state = _uiState;
    final goal = state.goal;
    final accuracy = state.accuracyPercent / 100;
    final error = state.startsNewGoal || goal == null
        ? await _deps.saveGoal.create(
            targetSet: state.targetSet,
            targetAccuracy: accuracy,
            deadlineDays: state.deadlineDays,
            now: _deps.clock(),
          )
        : await _deps.saveGoal.update(
            goal: goal,
            targetSet: state.targetSet,
            targetAccuracy: accuracy,
            deadlineDays: state.deadlineDays,
          );
    _setState(
      error == null
          ? _uiState.copyWith(isSaved: true, clearError: true)
          : _uiState.copyWith(error: error),
    );
  }

  void _setState(GoalUiState state) {
    _uiState = state;
    notify();
  }
}
