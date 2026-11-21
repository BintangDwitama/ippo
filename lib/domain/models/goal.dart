import 'package:ippo/domain/models/item.dart';
import 'package:meta/meta.dart';

/// Which kana a goal covers.
///
/// Stored by name. The first three keep the meaning they had before
/// voiced and combination kana existed, so older goals cover the same
/// kana as when they were set.
enum GoalTargetSet {
  /// The 46 basic hiragana.
  hiragana,

  /// The 46 basic katakana.
  katakana,

  /// The basic kana of both scripts.
  both,

  /// The voiced and combination hiragana.
  hiraganaExtended,

  /// The voiced and combination katakana.
  katakanaExtended,

  /// Every kana.
  everything;

  bool includes(KanaPayload kana) {
    final isBasic = kana.group == KanaGroup.basic;
    final isHiragana = kana.script == KanaScript.hiragana;
    return switch (this) {
      GoalTargetSet.hiragana => isHiragana && isBasic,
      GoalTargetSet.katakana => !isHiragana && isBasic,
      GoalTargetSet.both => isBasic,
      GoalTargetSet.hiraganaExtended => isHiragana && !isBasic,
      GoalTargetSet.katakanaExtended => !isHiragana && !isBasic,
      GoalTargetSet.everything => true,
    };
  }

  /// The target to suggest once a goal for this one has been achieved:
  /// the next step of the teaching path. Null at the end of a path.
  GoalTargetSet? get next => switch (this) {
        GoalTargetSet.hiragana => GoalTargetSet.hiraganaExtended,
        GoalTargetSet.hiraganaExtended => GoalTargetSet.katakana,
        GoalTargetSet.katakana => GoalTargetSet.katakanaExtended,
        GoalTargetSet.both => GoalTargetSet.everything,
        GoalTargetSet.katakanaExtended || GoalTargetSet.everything => null,
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
