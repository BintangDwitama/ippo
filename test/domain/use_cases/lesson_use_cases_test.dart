import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/unit_of_work.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/use_cases/build_choice_options.dart';
import 'package:ippo/domain/use_cases/complete_lesson.dart';
import 'package:ippo/domain/use_cases/get_next_lesson.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/fake_scheduler.dart';
import '../../support/builders.dart';

class _FailingUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) =>
      Future.error(StateError('transaction failed'));
}

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final yesterday = DateTime(2026, 1, 9, 9);

  group('GetNextLesson', () {
    const getNextLesson = GetNextLesson();
    final hiraganaGoal = goal(createdAt: now);

    test('the first lesson is the first five hiragana', () {
      final lesson = getNextLesson(
        items: kanaItems(hiraganaCount: 46, katakanaCount: 6),
        goal: hiraganaGoal,
        now: now,
      );

      expect(lesson.map((i) => i.kana.character), ['あ', 'い', 'う', 'え', 'お']);
    });

    test('the next lesson continues in teaching order', () {
      final lesson = getNextLesson(
        items: kanaItems(
          hiraganaCount: 46,
          introduced: 5,
          introducedAt: yesterday,
        ),
        goal: hiraganaGoal,
        now: now,
      );

      expect(lesson.map((i) => i.kana.character), ['か', 'き', 'く', 'け', 'こ']);
    });

    test('no lesson is offered once today\'s quota is used up', () {
      // 46 kana over 14 days is a quota of 4; five were introduced today.
      final lesson = getNextLesson(
        items: kanaItems(hiraganaCount: 46, introduced: 5, introducedAt: now),
        goal: hiraganaGoal,
        now: now,
      );

      expect(lesson, isEmpty);
    });

    test('falling behind allows more than one lesson a day', () {
      // 41 kana left with 5 days to go is a quota of 9.
      final lateGoal = goal(createdAt: DateTime(2026, 1, 1), deadlineDays: 14);
      final lesson = getNextLesson(
        items: kanaItems(hiraganaCount: 46, introduced: 5, introducedAt: now),
        goal: lateGoal,
        now: now,
      );

      expect(lesson, hasLength(5));
    });

    test('a hiragana goal never introduces katakana', () {
      final lesson = getNextLesson(
        items: kanaItems(
          hiraganaCount: 12,
          katakanaCount: 6,
          introduced: 12,
          introducedAt: yesterday,
        ),
        goal: hiraganaGoal,
        now: now,
      );

      expect(lesson, isEmpty);
    });

    test('katakana follow once all hiragana are introduced', () {
      final lesson = getNextLesson(
        items: kanaItems(
          hiraganaCount: 12,
          katakanaCount: 6,
          introduced: 12,
          introducedAt: yesterday,
        ),
        goal: goal(createdAt: now, targetSet: GoalTargetSet.both),
        now: now,
      );

      expect(lesson.first.kana.character, 'ア');
      expect(lesson.every((i) => i.kana.script == KanaScript.katakana), isTrue);
    });

    test('without an active goal, lessons run at the default pace', () {
      final items = kanaItems(hiraganaCount: 12);

      expect(getNextLesson(items: items, goal: null, now: now), hasLength(5));
      expect(
        getNextLesson(
          items: items,
          goal: goal(createdAt: now, status: GoalStatus.achieved),
          now: now,
        ),
        hasLength(5),
      );
      expect(
        getNextLesson(
          items: kanaItems(hiraganaCount: 12, introduced: 5, introducedAt: now),
          goal: null,
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('BuildChoiceOptions', () {
    const buildChoiceOptions = BuildChoiceOptions();

    test('offers four distinct options including the correct one', () {
      final items = kanaItems(hiraganaCount: 12, introduced: 12);

      final options = buildChoiceOptions(
        correct: items[5],
        allItems: items,
        random: Random(1),
      );

      expect(options, hasLength(4));
      expect(options.map((i) => i.id).toSet(), hasLength(4));
      expect(options, contains(items[5]));
    });

    test('wrong options come from the same script', () {
      final items =
          kanaItems(hiraganaCount: 12, katakanaCount: 6, introduced: 18);

      final options = buildChoiceOptions(
        correct: items.last,
        allItems: items,
        random: Random(2),
      );

      expect(
        options.every((i) => i.kana.script == KanaScript.katakana),
        isTrue,
      );
    });

    test('prefers introduced kana for the wrong options', () {
      final items = kanaItems(hiraganaCount: 12, introduced: 4);

      final options = buildChoiceOptions(
        correct: items[0],
        allItems: items,
        random: Random(3),
      );

      expect(options.every((i) => i.isIntroduced), isTrue);
    });

    test('in the first lesson, uses the lesson\'s kana then the nearest', () {
      final items = kanaItems(hiraganaCount: 12);
      final lesson = items.take(3).toList();

      final options = buildChoiceOptions(
        correct: items[0],
        allItems: items,
        random: Random(4),
        preferred: lesson,
      );

      expect(
        options.map((i) => i.kana.character).toSet(),
        {'あ', 'い', 'う', 'え'},
      );
    });

    test('the order of options varies with the random source', () {
      final items = kanaItems(hiraganaCount: 12, introduced: 12);
      List<int> ids(int seed) => buildChoiceOptions(
            correct: items[0],
            allItems: items,
            random: Random(seed),
          ).map((i) => i.id).toList();

      final orders = {for (var seed = 0; seed < 10; seed++) ids(seed).join(',')};
      expect(orders.length, greaterThan(1));
    });
  });

  group('CompleteLesson', () {
    test('marks kana introduced and creates both choice cards', () async {
      final all = kanaItems(hiraganaCount: 12);
      final items = FakeItemRepository(all);
      final cards = FakeCardRepository();
      final completeLesson = CompleteLesson(
        itemRepository: items,
        cardRepository: cards,
        unitOfWork: FakeUnitOfWork(),
        scheduler: FakeScheduler(),
      );

      await completeLesson(items: all.take(5).toList(), now: now);

      final saved = await items.getItems();
      expect(saved.where((i) => i.isIntroduced), hasLength(5));
      expect(saved[4].introducedAt, now);
      final created = await cards.getCards();
      expect(created, hasLength(10));
      expect(
        created.where((c) => c.itemId == 1).map((c) => c.promptType).toSet(),
        {PromptType.charToSoundChoice, PromptType.soundToCharChoice},
      );
      expect(created.every((c) => c.isDueAt(now)), isTrue);
    });

    test('a lesson that is never completed writes nothing', () async {
      final all = kanaItems(hiraganaCount: 12);
      final items = FakeItemRepository(all);
      final cards = FakeCardRepository();
      final completeLesson = CompleteLesson(
        itemRepository: items,
        cardRepository: cards,
        unitOfWork: _FailingUnitOfWork(),
        scheduler: FakeScheduler(),
      );

      await expectLater(
        completeLesson(items: all.take(5).toList(), now: now),
        throwsStateError,
      );

      expect((await items.getItems()).any((i) => i.isIntroduced), isFalse);
      expect(await cards.getCards(), isEmpty);
    });
  });
}
