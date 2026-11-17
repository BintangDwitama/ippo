import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/use_cases/build_review_session.dart';
import 'package:ippo/domain/use_cases/check_typed_answer.dart';
import 'package:ippo/domain/use_cases/grade_answer.dart';
import 'package:ippo/domain/use_cases/review_session.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/fake_scheduler.dart';
import '../../support/builders.dart';

void main() {
  final now = DateTime.utc(2026, 1, 10, 9);

  group('CheckTypedAnswer', () {
    const check = CheckTypedAnswer();
    const ka = KanaPayload(
      character: 'か',
      script: KanaScript.hiragana,
      romaji: 'ka',
    );
    const tsu = KanaPayload(
      character: 'つ',
      script: KanaScript.hiragana,
      romaji: 'tsu',
      alternativeRomaji: ['tu'],
    );

    test('accepts the reading', () {
      expect(check(ka, 'ka'), isTrue);
    });

    test('ignores case and surrounding whitespace', () {
      expect(check(ka, ' KA '), isTrue);
    });

    test('accepts an alternative romanisation', () {
      expect(check(tsu, 'tu'), isTrue);
      expect(check(tsu, 'tsu'), isTrue);
    });

    test('rejects a wrong or empty answer', () {
      expect(check(ka, 'ki'), isFalse);
      expect(check(ka, ''), isFalse);
      expect(check(ka, '   '), isFalse);
    });
  });

  group('BuildReviewSession', () {
    const build = BuildReviewSession();

    List<ReviewCard> cardsDue(int count, {int cardsPerItem = 1}) => [
          for (var i = 0; i < count; i++)
            reviewCard(
              id: i + 1,
              itemId: i ~/ cardsPerItem + 1,
              promptType: PromptType.values[i % cardsPerItem],
              due: now.subtract(Duration(hours: i)),
            ),
        ];

    test('contains every due card when under the cap', () {
      final session = build(
        cards: cardsDue(12),
        now: now,
        remainingCap: 100,
        voiceAvailable: true,
        random: Random(1),
      );

      expect(session, hasLength(12));
    });

    test('leaves out cards that are not yet due', () {
      final session = build(
        cards: [
          reviewCard(id: 1, itemId: 1, due: now),
          reviewCard(id: 2, itemId: 2, due: now.add(const Duration(days: 1))),
        ],
        now: now,
        remainingCap: 100,
        voiceAvailable: true,
        random: Random(1),
      );

      expect(session.map((c) => c.id), [1]);
    });

    test('keeps the most overdue cards when over the cap', () {
      // Card ids rise with how overdue they are.
      final session = build(
        cards: cardsDue(150),
        now: now,
        remainingCap: 100,
        voiceAvailable: true,
        random: Random(1),
      );

      expect(session, hasLength(100));
      expect(session.every((c) => c.id > 50), isTrue);
    });

    test('is empty when the cap is used up', () {
      final session = build(
        cards: cardsDue(5),
        now: now,
        remainingCap: 0,
        voiceAvailable: true,
        random: Random(1),
      );

      expect(session, isEmpty);
    });

    test('skips listening cards when no voice is available', () {
      final cards = [
        reviewCard(id: 1, itemId: 1, due: now),
        reviewCard(
          id: 2,
          itemId: 1,
          promptType: PromptType.soundToCharChoice,
          due: now,
        ),
      ];

      final session = build(
        cards: cards,
        now: now,
        remainingCap: 100,
        voiceAvailable: false,
        random: Random(1),
      );

      expect(session.map((c) => c.id), [1]);
    });

    test('never shows the same kana twice in a row when avoidable', () {
      for (var seed = 0; seed < 20; seed++) {
        final session = build(
          cards: cardsDue(12, cardsPerItem: 2),
          now: now,
          remainingCap: 100,
          voiceAvailable: true,
          random: Random(seed),
        );

        for (var i = 1; i < session.length; i++) {
          expect(
            session[i].itemId,
            isNot(session[i - 1].itemId),
            reason: 'seed $seed, position $i',
          );
        }
      }
    });

    test('mixes prompt types instead of grouping them', () {
      final session = build(
        cards: cardsDue(40, cardsPerItem: 2),
        now: now,
        remainingCap: 100,
        voiceAvailable: true,
        random: Random(7),
      );
      final firstHalf = session.take(20).map((c) => c.promptType).toSet();

      expect(firstHalf, hasLength(2));
    });
  });

  group('GradeAnswer', () {
    late FakeCardRepository cards;
    late FakeReviewRepository reviews;
    late FakeScheduler scheduler;
    late GradeAnswer gradeAnswer;

    Future<ReviewCard> seedCard({
      PromptType promptType = PromptType.charToSoundChoice,
    }) {
      return cards.createCard(
        itemId: 1,
        promptType: promptType,
        scheduling: scheduler.initialState(now),
        createdAt: now,
      );
    }

    setUp(() {
      cards = FakeCardRepository();
      reviews = FakeReviewRepository();
      scheduler = FakeScheduler();
      gradeAnswer = GradeAnswer(
        cardRepository: cards,
        reviewRepository: reviews,
        unitOfWork: FakeUnitOfWork(),
        scheduler: scheduler,
      );
    });

    test('a correct answer is rated good and rescheduled later', () async {
      final card = await seedCard();

      final updated = await gradeAnswer(card: card, wasCorrect: true, now: now);

      expect(scheduler.ratings, [Rating.good]);
      expect(updated.due, now.add(const Duration(days: 1)));
      expect(updated.reps, 1);
      expect(updated.lapses, 0);
      expect(updated.consecutiveCorrect, 1);
      expect((await cards.getCards()).single.due, updated.due);
    });

    test('a wrong answer is rated again and counts as a lapse', () async {
      final card = await seedCard();

      final updated =
          await gradeAnswer(card: card, wasCorrect: false, now: now);

      expect(scheduler.ratings, [Rating.again]);
      expect(updated.due.difference(now), lessThan(const Duration(days: 1)));
      expect(updated.lapses, 1);
      expect(updated.consecutiveCorrect, 0);
    });

    test('every answer is recorded', () async {
      final card = await seedCard();

      final first = await gradeAnswer(card: card, wasCorrect: false, now: now);
      await gradeAnswer(
        card: first,
        wasCorrect: true,
        now: now.add(const Duration(days: 2)),
      );

      final records = await reviews.getReviews();
      expect(records.map((r) => r.wasCorrect), [false, true]);
      expect(records.first.phaseBefore, CardPhase.learning);
      expect(records.first.elapsedDays, 0);
      expect(records.last.elapsedDays, 2);
      expect(records.last.cardId, card.id);
    });

    test('the third correct answer in a row unlocks the typed card', () async {
      var card = await seedCard();

      for (var i = 0; i < 2; i++) {
        card = await gradeAnswer(card: card, wasCorrect: true, now: now);
      }
      expect(await cards.getCards(), hasLength(1));

      await gradeAnswer(card: card, wasCorrect: true, now: now);

      final all = await cards.getCards();
      expect(all, hasLength(2));
      final typed =
          all.singleWhere((c) => c.promptType == PromptType.charToSoundTyped);
      expect(typed.itemId, 1);
      expect(typed.isDueAt(now), isTrue);
    });

    test('a wrong answer restarts the count towards the typed card', () async {
      var card = await seedCard();

      card = await gradeAnswer(card: card, wasCorrect: true, now: now);
      card = await gradeAnswer(card: card, wasCorrect: true, now: now);
      card = await gradeAnswer(card: card, wasCorrect: false, now: now);
      card = await gradeAnswer(card: card, wasCorrect: true, now: now);

      expect(card.consecutiveCorrect, 1);
      expect(await cards.getCards(), hasLength(1));
    });

    test('listening cards never unlock a typed card', () async {
      var card = await seedCard(promptType: PromptType.soundToCharChoice);

      for (var i = 0; i < 4; i++) {
        card = await gradeAnswer(card: card, wasCorrect: true, now: now);
      }

      expect(await cards.getCards(), hasLength(1));
    });

    test('further correct answers do not duplicate the typed card', () async {
      var card = await seedCard();

      for (var i = 0; i < 5; i++) {
        card = await gradeAnswer(card: card, wasCorrect: true, now: now);
      }

      expect(await cards.getCards(), hasLength(2));
    });
  });

  group('ReviewSession', () {
    List<ReviewCard> sessionCards(int count) =>
        [for (var i = 1; i <= count; i++) reviewCard(id: i, itemId: i)];

    test('finishes after every card is answered correctly', () {
      final session = ReviewSession(sessionCards(3));

      for (var i = 0; i < 3; i++) {
        session.recordAnswer(wasCorrect: true);
      }

      expect(session.isFinished, isTrue);
      expect(session.current, isNull);
      expect(session.reviewedCount, 3);
      expect(session.accuracy, 1);
    });

    test('a wrong card returns later, after other cards', () {
      final session = ReviewSession(sessionCards(5));

      session.recordAnswer(wasCorrect: false);

      expect(session.current!.id, 2);
      session.recordAnswer(wasCorrect: true);
      expect(session.current!.id, 3);
      session.recordAnswer(wasCorrect: true);
      expect(session.current!.id, 1);
      expect(session.isRepeat, isTrue);
    });

    test('a wrong card keeps returning until answered correctly', () {
      final session = ReviewSession(sessionCards(1));

      session.recordAnswer(wasCorrect: false);
      expect(session.isFinished, isFalse);
      session.recordAnswer(wasCorrect: false);
      expect(session.isFinished, isFalse);
      session.recordAnswer(wasCorrect: true);

      expect(session.isFinished, isTrue);
    });

    test('accuracy counts first attempts only', () {
      final session = ReviewSession(sessionCards(4));

      session.recordAnswer(wasCorrect: false); // card 1, first attempt
      session.recordAnswer(wasCorrect: true); // card 2
      session.recordAnswer(wasCorrect: true); // card 3
      session.recordAnswer(wasCorrect: true); // card 1 again: practice
      session.recordAnswer(wasCorrect: true); // card 4

      expect(session.isFinished, isTrue);
      expect(session.reviewedCount, 4);
      expect(session.correctFirstAttempts, 3);
      expect(session.accuracy, 0.75);
    });

    test('a first attempt is not a repeat', () {
      final session = ReviewSession(sessionCards(2));

      expect(session.isRepeat, isFalse);
    });

    test('a returning card avoids sitting next to its own kana', () {
      final session = ReviewSession([
        reviewCard(id: 1, itemId: 1),
        reviewCard(id: 2, itemId: 2),
        reviewCard(id: 3, itemId: 3),
        reviewCard(
          id: 4,
          itemId: 1,
          promptType: PromptType.soundToCharChoice,
        ),
        reviewCard(id: 5, itemId: 5),
      ]);

      session.recordAnswer(wasCorrect: false);
      final order = <int>[];
      while (!session.isFinished) {
        order.add(session.current!.id);
        session.recordAnswer(wasCorrect: true);
      }

      expect(order, [2, 3, 4, 5, 1]);
    });
  });
}
