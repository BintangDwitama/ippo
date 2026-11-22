import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:meta/meta.dart';

/// Everything that belongs to the learner, independent of the database.
///
/// Items are named by their stable key (for example "hiragana:ka"), never
/// by a row id, so a snapshot can be restored into any install.
@immutable
class BackupSnapshot {
  const BackupSnapshot({
    required this.exportedAt,
    this.introducedItems = const [],
    this.learnerMnemonics = const [],
    this.cards = const [],
    this.goals = const [],
    this.settings = const BackupSettings(),
  });

  /// When the snapshot was taken. Always UTC.
  final DateTime exportedAt;
  final List<BackupItem> introducedItems;
  final List<BackupMnemonic> learnerMnemonics;
  final List<BackupCard> cards;

  /// Oldest first; the last one is the current goal.
  final List<BackupGoal> goals;
  final BackupSettings settings;

  int get reviewCount =>
      cards.fold(0, (count, card) => count + card.reviews.length);

  /// This snapshot without anything that belongs to the items named by
  /// [keys]: their introduction, mnemonics, cards and review history.
  BackupSnapshot without(Set<String> keys) {
    if (keys.isEmpty) return this;
    return BackupSnapshot(
      exportedAt: exportedAt,
      introducedItems: [
        for (final item in introducedItems)
          if (!keys.contains(item.key)) item,
      ],
      learnerMnemonics: [
        for (final mnemonic in learnerMnemonics)
          if (!keys.contains(mnemonic.key)) mnemonic,
      ],
      cards: [
        for (final card in cards)
          if (!keys.contains(card.itemKey)) card,
      ],
      goals: goals,
      settings: settings,
    );
  }

  /// Every item key the snapshot refers to.
  Set<String> get itemKeys => {
    for (final item in introducedItems) item.key,
    for (final mnemonic in learnerMnemonics) mnemonic.key,
    for (final card in cards) card.itemKey,
  };
}

/// An item a lesson has introduced.
@immutable
class BackupItem {
  const BackupItem({required this.key, required this.introducedAt});

  final String key;
  final DateTime introducedAt;
}

/// A mnemonic the learner wrote themselves.
@immutable
class BackupMnemonic {
  const BackupMnemonic({required this.key, required this.learnerText});

  final String key;
  final String learnerText;
}

@immutable
class BackupCard {
  const BackupCard({
    required this.itemKey,
    required this.promptType,
    required this.scheduling,
    required this.createdAt,
    this.reps = 0,
    this.lapses = 0,
    this.consecutiveCorrect = 0,
    this.reviews = const [],
  });

  final String itemKey;
  final PromptType promptType;
  final SchedulingState scheduling;
  final DateTime createdAt;
  final int reps;
  final int lapses;
  final int consecutiveCorrect;

  /// This card's history, oldest first.
  final List<BackupReview> reviews;
}

@immutable
class BackupReview {
  const BackupReview({
    required this.reviewedAt,
    required this.rating,
    required this.wasCorrect,
    required this.phaseBefore,
    required this.elapsedDays,
  });

  final DateTime reviewedAt;
  final Rating rating;
  final bool wasCorrect;
  final CardPhase phaseBefore;
  final int elapsedDays;
}

@immutable
class BackupGoal {
  const BackupGoal({
    required this.targetSet,
    required this.targetAccuracy,
    required this.createdAt,
    required this.deadline,
    required this.status,
  });

  final GoalTargetSet targetSet;
  final double targetAccuracy;
  final DateTime createdAt;
  final DateTime deadline;
  final GoalStatus status;
}

/// The learner's preferences. Device state, such as notices already
/// shown, is deliberately not part of a backup.
@immutable
class BackupSettings {
  const BackupSettings({
    this.dailyReviewCap = 100,
    this.reminderTime,
    this.appearanceMode = AppearanceMode.automatic,
  });

  final int dailyReviewCap;

  /// Null when the reminder is off.
  final ReminderTime? reminderTime;
  final AppearanceMode appearanceMode;
}

/// What a snapshot holds, in numbers, for the learner to check before
/// replacing their data.
@immutable
class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.introducedCount,
    required this.wordCount,
    required this.cardCount,
    required this.reviewCount,
  });

  factory BackupSummary.of(BackupSnapshot snapshot) {
    return BackupSummary(
      exportedAt: snapshot.exportedAt,
      introducedCount: snapshot.introducedItems
          .where((item) => !item.key.startsWith(wordKeyPrefix))
          .length,
      wordCount: snapshot.introducedItems
          .where((item) => item.key.startsWith(wordKeyPrefix))
          .length,
      cardCount: snapshot.cards.length,
      reviewCount: snapshot.reviewCount,
    );
  }

  final DateTime exportedAt;

  /// Kana that have been introduced.
  final int introducedCount;

  /// Words that have been introduced.
  final int wordCount;
  final int cardCount;
  final int reviewCount;
}
