import 'package:ippo/data/repositories/goal_repository.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/study_calendar.dart';

/// Why a goal could not be saved.
enum GoalValidationError { deadlineTooShort, accuracyOutOfRange }

/// Creates and edits the learner's goal.
class SaveGoal {
  SaveGoal({required this._goalRepository});

  static const GoalTargetSet presetTargetSet = GoalTargetSet.hiragana;
  static const double presetAccuracy = 0.9;
  static const int presetDeadlineDays = 14;

  static const double minAccuracy = 0.5;
  static const double maxAccuracy = 1.0;

  final GoalRepository _goalRepository;

  /// Returns the problem with the given values, or null if they are valid.
  GoalValidationError? validate({
    required double targetAccuracy,
    required int deadlineDays,
  }) {
    if (deadlineDays < 1) return GoalValidationError.deadlineTooShort;
    if (targetAccuracy < minAccuracy || targetAccuracy > maxAccuracy) {
      return GoalValidationError.accuracyOutOfRange;
    }
    return null;
  }

  /// Starts a new goal whose deadline is [deadlineDays] days after [now].
  /// Returns a validation error and saves nothing if the values are invalid.
  Future<GoalValidationError?> create({
    required GoalTargetSet targetSet,
    required double targetAccuracy,
    required int deadlineDays,
    required DateTime now,
  }) async {
    final error =
        validate(targetAccuracy: targetAccuracy, deadlineDays: deadlineDays);
    if (error != null) return error;
    await _goalRepository.createGoal(
      targetSet: targetSet,
      targetAccuracy: targetAccuracy,
      createdAt: now,
      deadline: _deadline(now, deadlineDays),
    );
    return null;
  }

  /// Changes [goal]; the deadline is counted from the day it was created.
  /// An edited goal becomes active again.
  Future<GoalValidationError?> update({
    required Goal goal,
    required GoalTargetSet targetSet,
    required double targetAccuracy,
    required int deadlineDays,
  }) async {
    final error =
        validate(targetAccuracy: targetAccuracy, deadlineDays: deadlineDays);
    if (error != null) return error;
    await _goalRepository.updateGoal(
      Goal(
        id: goal.id,
        targetSet: targetSet,
        targetAccuracy: targetAccuracy,
        createdAt: goal.createdAt,
        deadline: _deadline(goal.createdAt, deadlineDays),
      ),
    );
    return null;
  }

  DateTime _deadline(DateTime from, int days) {
    final local = from.toLocal();
    return DateTime(local.year, local.month, local.day + days);
  }

  /// The deadline of [goal] as a number of days from its creation.
  static int deadlineDaysOf(Goal goal) =>
      StudyCalendar.daysBetween(goal.createdAt, goal.deadline);
}
