import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// A snapshot that uses every part of the backup format: two introduced
/// kana, one learner mnemonic, cards in different phases with and without
/// history, two goals and non-default settings.
///
/// It names the kana in [keys], which must have at least two entries.
BackupSnapshot fullSnapshot({
  List<String> keys = const ['hiragana:a', 'hiragana:i'],
  DateTime? exportedAt,
}) {
  final introducedAt = DateTime.utc(2026, 11, 20, 11, 2);
  return BackupSnapshot(
    exportedAt: exportedAt ?? DateTime.utc(2026, 11, 21, 2, 15),
    introducedItems: [
      for (final key in keys.take(2))
        BackupItem(key: key, introducedAt: introducedAt),
    ],
    learnerMnemonics: [
      BackupMnemonic(key: keys[0], learnerText: 'an apple with a stalk'),
    ],
    cards: [
      BackupCard(
        itemKey: keys[0],
        promptType: PromptType.charToSoundChoice,
        scheduling: SchedulingState(
          phase: CardPhase.review,
          due: DateTime.utc(2026, 11, 25, 11, 30),
          stability: 4.25,
          difficulty: 5.5,
          lastReview: DateTime.utc(2026, 11, 21, 1),
        ),
        createdAt: introducedAt,
        reps: 3,
        lapses: 1,
        consecutiveCorrect: 2,
        reviews: [
          BackupReview(
            reviewedAt: DateTime.utc(2026, 11, 20, 11, 5),
            rating: Rating.again,
            wasCorrect: false,
            phaseBefore: CardPhase.learning,
            elapsedDays: 0,
          ),
          BackupReview(
            reviewedAt: DateTime.utc(2026, 11, 21, 1),
            rating: Rating.good,
            wasCorrect: true,
            phaseBefore: CardPhase.learning,
            elapsedDays: 1,
          ),
        ],
      ),
      BackupCard(
        itemKey: keys[0],
        promptType: PromptType.charToSoundTyped,
        scheduling: SchedulingState(
          phase: CardPhase.relearning,
          step: 1,
          due: DateTime.utc(2026, 11, 21, 1, 10),
          stability: 0.5,
          difficulty: 7,
          lastReview: DateTime.utc(2026, 11, 21, 1),
        ),
        createdAt: DateTime.utc(2026, 11, 21, 1),
        reps: 1,
        lapses: 1,
      ),
      BackupCard(
        itemKey: keys[1],
        promptType: PromptType.soundToCharChoice,
        scheduling: SchedulingState(
          phase: CardPhase.learning,
          step: 0,
          due: DateTime.utc(2026, 11, 20, 11, 12),
        ),
        createdAt: introducedAt,
      ),
    ],
    goals: [
      BackupGoal(
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.8,
        createdAt: DateTime.utc(2026, 11, 1, 3),
        deadline: DateTime.utc(2026, 11, 14, 17),
        status: GoalStatus.missed,
      ),
      BackupGoal(
        targetSet: GoalTargetSet.both,
        targetAccuracy: 0.9,
        createdAt: DateTime.utc(2026, 11, 19, 3),
        deadline: DateTime.utc(2026, 12, 2, 17),
        status: GoalStatus.active,
      ),
    ],
    settings: const BackupSettings(
      dailyReviewCap: 60,
      reminderTime: ReminderTime(hour: 19, minute: 30),
      appearanceMode: AppearanceMode.paper,
    ),
  );
}
