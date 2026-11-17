import 'package:ippo/domain/models/item.dart';
import 'package:meta/meta.dart';

/// Which kana a goal covers.
enum GoalTargetSet {
  hiragana,
  katakana,
  both;

  bool includes(KanaScript script) => switch (this) {
        GoalTargetSet.hiragana => script == KanaScript.hiragana,
        GoalTargetSet.katakana => script == KanaScript.katakana,
        GoalTargetSet.both => true,
      };
}

enum GoalStatus { active, achieved, missed }

/// A SMART goal: a set of kana, an accuracy to reach, and a deadline.
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.targetSet,
    required this.targetAccuracy,
    required this.createdAt,
    required this.deadline,
    this.status = GoalStatus.active,
  });

  final int id;
  final GoalTargetSet targetSet;

  /// Between 0.5 and 1.0.
  final double targetAccuracy;

  final DateTime createdAt;

  /// The last day of the goal, at local midnight.
  final DateTime deadline;

  final GoalStatus status;
}
