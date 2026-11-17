import 'package:drift/drift.dart';
import 'package:ippo/data/repositories/goal_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/goal.dart';

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$GoalsTable, GoalRow> get _latest =>
      _db.select(_db.goals)
        ..orderBy([
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
        ])
        ..limit(1);

  @override
  Stream<Goal?> getCurrentGoalStream() {
    return _latest
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toGoal(row));
  }

  @override
  Future<Goal?> getCurrentGoal() async {
    final row = await _latest.getSingleOrNull();
    return row == null ? null : _toGoal(row);
  }

  @override
  Future<Goal> createGoal({
    required GoalTargetSet targetSet,
    required double targetAccuracy,
    required DateTime createdAt,
    required DateTime deadline,
  }) async {
    final row = await _db.into(_db.goals).insertReturning(
          GoalsCompanion.insert(
            targetSet: targetSet,
            targetAccuracy: targetAccuracy,
            createdAt: createdAt,
            deadline: deadline,
            status: GoalStatus.active,
          ),
        );
    return _toGoal(row);
  }

  @override
  Future<void> updateGoal(Goal goal) {
    return (_db.update(_db.goals)..where((t) => t.id.equals(goal.id))).write(
      GoalsCompanion(
        targetSet: Value(goal.targetSet),
        targetAccuracy: Value(goal.targetAccuracy),
        deadline: Value(goal.deadline),
        status: Value(goal.status),
      ),
    );
  }

  Goal _toGoal(GoalRow row) {
    return Goal(
      id: row.id,
      targetSet: row.targetSet,
      targetAccuracy: row.targetAccuracy,
      createdAt: row.createdAt,
      deadline: row.deadline,
      status: row.status,
    );
  }
}
