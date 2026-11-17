import 'package:ippo/domain/models/goal.dart';

/// Access to the learner's goals.
abstract interface class GoalRepository {
  /// The most recently created goal, whatever its status; null if none.
  Stream<Goal?> getCurrentGoalStream();

  Future<Goal?> getCurrentGoal();

  Future<Goal> createGoal({
    required GoalTargetSet targetSet,
    required double targetAccuracy,
    required DateTime createdAt,
    required DateTime deadline,
  });

  Future<void> updateGoal(Goal goal);
}
