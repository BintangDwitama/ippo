import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/calculate_daily_quota.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/domain/use_cases/get_study_stats.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';

import '../../fakes/fake_repositories.dart';
import '../../support/builders.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);

  group('CalculateDailyQuota', () {
    const quota = CalculateDailyQuota();

    test('spreads the remaining kana evenly, rounding up', () {
      expect(quota(notIntroduced: 46, daysRemaining: 14), 4);
    });

    test('rises when the learner falls behind', () {
      expect(quota(notIntroduced: 40, daysRemaining: 5), 8);
    });

    test('is zero when everything is introduced', () {
      expect(quota(notIntroduced: 0, daysRemaining: 5), 0);
    });

    test('is never less than one while kana remain', () {
      expect(quota(notIntroduced: 3, daysRemaining: 30), 1);
    });

    test('treats the deadline day and later as one day left', () {
      expect(quota(notIntroduced: 7, daysRemaining: 0), 7);
      expect(quota(notIntroduced: 7, daysRemaining: -2), 7);
    });

    test('remainingToday subtracts what was introduced today', () {
      // The day started with 46 to go over 14 days: a quota of 4.
      expect(
        quota.remainingToday(
          notIntroduced: 44,
          introducedToday: 2,
          daysRemaining: 14,
        ),
        2,
      );
      expect(
        quota.remainingToday(
          notIntroduced: 41,
          introducedToday: 5,
          daysRemaining: 14,
        ),
        0,
      );
    });
  });

  group('SaveGoal', () {
    late FakeGoalRepository goals;
    late SaveGoal saveGoal;

    setUp(() {
      goals = FakeGoalRepository();
      saveGoal = SaveGoal(goalRepository: goals);
    });

    test('creates the preset goal with a deadline 14 days away', () async {
      final error = await saveGoal.create(
        targetSet: SaveGoal.presetTargetSet,
        targetAccuracy: SaveGoal.presetAccuracy,
        deadlineDays: SaveGoal.presetDeadlineDays,
        now: now,
      );

      final created = await goals.getCurrentGoal();
      expect(error, isNull);
      expect(created!.targetSet, GoalTargetSet.hiragana);
      expect(created.targetAccuracy, 0.9);
      expect(created.deadline, DateTime(2026, 1, 24));
      expect(created.status, GoalStatus.active);
    });

    test('rejects a deadline of zero days', () async {
      final error = await saveGoal.create(
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.9,
        deadlineDays: 0,
        now: now,
      );

      expect(error, GoalValidationError.deadlineTooShort);
      expect(await goals.getCurrentGoal(), isNull);
    });

    test('rejects an accuracy outside 50% to 100%', () async {
      expect(
        await saveGoal.create(
          targetSet: GoalTargetSet.hiragana,
          targetAccuracy: 0.49,
          deadlineDays: 14,
          now: now,
        ),
        GoalValidationError.accuracyOutOfRange,
      );
      expect(
        await saveGoal.create(
          targetSet: GoalTargetSet.hiragana,
          targetAccuracy: 1.01,
          deadlineDays: 14,
          now: now,
        ),
        GoalValidationError.accuracyOutOfRange,
      );
      expect(await goals.getCurrentGoal(), isNull);
    });

    test('editing counts the deadline from the day of creation', () async {
      await saveGoal.create(
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.9,
        deadlineDays: 14,
        now: now,
      );
      final created = (await goals.getCurrentGoal())!;

      final error = await saveGoal.update(
        goal: created,
        targetSet: GoalTargetSet.both,
        targetAccuracy: 0.8,
        deadlineDays: 21,
      );

      final edited = (await goals.getCurrentGoal())!;
      expect(error, isNull);
      expect(edited.id, created.id);
      expect(edited.deadline, DateTime(2026, 1, 31));
      expect(edited.targetSet, GoalTargetSet.both);
      expect(SaveGoal.deadlineDaysOf(edited), 21);
    });

    test('an invalid edit leaves the goal unchanged', () async {
      await saveGoal.create(
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.9,
        deadlineDays: 14,
        now: now,
      );
      final created = (await goals.getCurrentGoal())!;

      final error = await saveGoal.update(
        goal: created,
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.9,
        deadlineDays: 0,
      );

      expect(error, GoalValidationError.deadlineTooShort);
      expect((await goals.getCurrentGoal())!.deadline, DateTime(2026, 1, 24));
    });
  });

  group('GetGoalProgress', () {
    const getProgress = GetGoalProgress();
    final created = DateTime(2026, 1, 4, 9);

    test('reports introduced count, accuracy and days remaining', () {
      final items = kanaItems(hiraganaCount: 46, introduced: 20);
      final cards = [
        for (var i = 1; i <= 20; i++) reviewCard(id: i, itemId: i),
      ];
      final reviews = [
        for (var i = 1; i <= 20; i++)
          reviewRecord(
            id: i,
            cardId: i,
            reviewedAt: now.subtract(const Duration(hours: 1)),
            wasCorrect: i <= 17,
          ),
      ];

      final progress = getProgress(
        goal: goal(createdAt: created),
        items: items,
        cards: cards,
        reviews: reviews,
        now: now,
      );

      expect(progress.introducedCount, 20);
      expect(progress.totalCount, 46);
      expect(progress.accuracy, 0.85);
      expect(progress.daysRemaining, 8);
      expect(progress.status, GoalStatus.active);
    });

    test('accuracy ignores old reviews and other scripts', () {
      final items = kanaItems(hiraganaCount: 5, katakanaCount: 2, introduced: 7);
      final cards = [
        reviewCard(id: 1, itemId: 1),
        reviewCard(id: 2, itemId: 101),
      ];
      final reviews = [
        reviewRecord(id: 1, cardId: 1, reviewedAt: now, wasCorrect: true),
        reviewRecord(
          id: 2,
          cardId: 1,
          reviewedAt: now.subtract(const Duration(days: 8)),
          wasCorrect: false,
        ),
        reviewRecord(id: 3, cardId: 2, reviewedAt: now, wasCorrect: false),
      ];

      final progress = getProgress(
        goal: goal(createdAt: created),
        items: items,
        cards: cards,
        reviews: reviews,
        now: now,
      );

      expect(progress.accuracy, 1);
      expect(progress.totalCount, 5);
    });

    test('accuracy is unknown without recent reviews', () {
      final progress = getProgress(
        goal: goal(createdAt: created),
        items: kanaItems(hiraganaCount: 5),
        cards: const [],
        reviews: const [],
        now: now,
      );

      expect(progress.accuracy, isNull);
      expect(progress.status, GoalStatus.active);
    });

    test('is achieved when all kana are introduced at the target accuracy',
        () {
      final items = kanaItems(hiraganaCount: 5, introduced: 5);
      final cards = [for (var i = 1; i <= 5; i++) reviewCard(id: i, itemId: i)];
      final reviews = [
        for (var i = 1; i <= 25; i++)
          reviewRecord(
            id: i,
            cardId: (i % 5) + 1,
            reviewedAt: now,
            wasCorrect: i <= 23,
          ),
      ];

      final progress = getProgress(
        goal: goal(createdAt: created),
        items: items,
        cards: cards,
        reviews: reviews,
        now: now,
      );

      expect(progress.accuracy, 0.92);
      expect(progress.status, GoalStatus.achieved);
    });

    test('is not achieved while accuracy is below the target', () {
      final items = kanaItems(hiraganaCount: 5, introduced: 5);
      final cards = [reviewCard(id: 1, itemId: 1)];
      final reviews = [
        reviewRecord(id: 1, cardId: 1, reviewedAt: now, wasCorrect: true),
        reviewRecord(id: 2, cardId: 1, reviewedAt: now, wasCorrect: false),
      ];

      final progress = getProgress(
        goal: goal(createdAt: created),
        items: items,
        cards: cards,
        reviews: reviews,
        now: now,
      );

      expect(progress.status, GoalStatus.active);
    });

    test('is missed once the deadline has passed', () {
      final progress = getProgress(
        goal: goal(createdAt: DateTime(2025, 12, 1)),
        items: kanaItems(hiraganaCount: 5, introduced: 2),
        cards: const [],
        reviews: const [],
        now: now,
      );

      expect(progress.status, GoalStatus.missed);
      expect(progress.daysRemaining, 0);
    });

    test('is still active on the deadline day itself', () {
      final progress = getProgress(
        goal: goal(createdAt: DateTime(2025, 12, 27)),
        items: kanaItems(hiraganaCount: 5, introduced: 2),
        cards: const [],
        reviews: const [],
        now: now,
      );

      expect(progress.daysRemaining, 0);
      expect(progress.status, GoalStatus.active);
    });

    test('an achieved goal stays achieved', () {
      final progress = getProgress(
        goal: goal(createdAt: DateTime(2025, 12, 1), status: GoalStatus.achieved),
        items: kanaItems(hiraganaCount: 5, introduced: 5),
        cards: const [],
        reviews: const [],
        now: now,
      );

      expect(progress.status, GoalStatus.achieved);
    });
  });

  group('GetStudyStats', () {
    const stats = GetStudyStats();

    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    test('the streak grows when the learner studies today', () {
      final reviews = [
        for (var day = 4; day >= 0; day--)
          reviewRecord(id: 5 - day, cardId: 1, reviewedAt: daysAgo(day)),
      ];

      expect(stats.streak(items: const [], reviews: reviews, now: now), 5);
    });

    test('a streak that reached yesterday is still alive', () {
      final reviews = [
        for (var day = 4; day >= 1; day--)
          reviewRecord(id: 5 - day, cardId: 1, reviewedAt: daysAgo(day)),
      ];

      expect(stats.streak(items: const [], reviews: reviews, now: now), 4);
    });

    test('missing yesterday resets the streak to zero', () {
      final reviews = [
        reviewRecord(id: 1, cardId: 1, reviewedAt: daysAgo(3)),
        reviewRecord(id: 2, cardId: 1, reviewedAt: daysAgo(2)),
      ];

      expect(stats.streak(items: const [], reviews: reviews, now: now), 0);
    });

    test('a completed lesson counts as a day of study', () {
      final items = kanaItems(hiraganaCount: 5, introduced: 5, introducedAt: now);
      final reviews = [reviewRecord(id: 1, cardId: 1, reviewedAt: daysAgo(1))];

      expect(stats.streak(items: items, reviews: reviews, now: now), 2);
    });

    test('several reviews on one day count once', () {
      final reviews = [
        reviewRecord(id: 1, cardId: 1, reviewedAt: now),
        reviewRecord(id: 2, cardId: 2, reviewedAt: now),
      ];

      expect(stats.streak(items: const [], reviews: reviews, now: now), 1);
    });

    test('the remaining cap counts only today\'s reviews', () {
      final reviews = [
        reviewRecord(id: 1, cardId: 1, reviewedAt: daysAgo(1)),
        for (var i = 2; i <= 31; i++)
          reviewRecord(id: i, cardId: 1, reviewedAt: now),
      ];

      expect(stats.reviewsToday(reviews: reviews, now: now), 30);
      expect(
        stats.remainingReviewCap(dailyCap: 100, reviews: reviews, now: now),
        70,
      );
      expect(
        stats.remainingReviewCap(dailyCap: 20, reviews: reviews, now: now),
        0,
      );
    });
  });
}
