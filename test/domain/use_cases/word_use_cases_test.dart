import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/item_payload_mapper.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/use_cases/build_choice_options.dart';
import 'package:ippo/domain/use_cases/build_word_choice_options.dart';
import 'package:ippo/domain/use_cases/complete_lesson.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/domain/use_cases/get_kana_status.dart';
import 'package:ippo/domain/use_cases/get_next_lesson.dart';
import 'package:ippo/domain/use_cases/get_next_word_lesson.dart';
import 'package:ippo/domain/use_cases/get_study_stats.dart';
import 'package:ippo/domain/use_cases/grade_answer.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/fake_scheduler.dart';
import '../../support/builders.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 8, 9);

  /// The あ and か rows, the first [introduced] of them learned.
  List<Item> kana({int introduced = 5}) =>
      kanaItems(hiraganaCount: 10, introduced: introduced, introducedAt: earlier);

  Item word(
    int id,
    String reading,
    List<String> kanaKeys, {
    List<String> meanings = const [],
    String partOfSpeech = 'noun',
    String? written,
    DateTime? introducedAt,
  }) {
    return wordItem(
      id: id,
      reading: reading,
      kanaKeys: kanaKeys,
      meanings: meanings.isEmpty ? ['meaning $id'] : meanings,
      partOfSpeech: partOfSpeech,
      written: written,
      introducedAt: introducedAt,
    );
  }

  const a = 'hiragana:a';
  const i = 'hiragana:i';
  const u = 'hiragana:u';
  const e = 'hiragana:e';
  const o = 'hiragana:o';
  const ka = 'hiragana:ka';

  group('word items', () {
    test('a word payload survives being stored', () {
      const mapper = ItemPayloadMapper();
      const payload = WordPayload(
        reading: 'あめ',
        written: '雨',
        meanings: ['rain'],
        partOfSpeech: 'noun',
        level: 5,
        kanaKeys: ['hiragana:a', 'hiragana:me'],
      );
      final back =
          mapper.decode(ItemKind.word, mapper.encode(payload)) as WordPayload;
      expect(back.reading, 'あめ');
      expect(back.written, '雨');
      expect(back.meanings, ['rain']);
      expect(back.partOfSpeech, 'noun');
      expect(back.level, 5);
      expect(back.kanaKeys, ['hiragana:a', 'hiragana:me']);
    });

    test('a word written in kana is stored without a written form', () {
      const mapper = ItemPayloadMapper();
      final json = mapper.encode(
        const WordPayload(
          reading: 'いい',
          meanings: ['good', 'fine'],
          partOfSpeech: 'i-adjective',
          level: 5,
          kanaKeys: ['hiragana:i'],
        ),
      );
      final back = mapper.decode(ItemKind.word, json) as WordPayload;
      expect(back.written, isNull);
      expect(back.meaningText, 'good; fine');
    });

    test('asking an item for the other kind of content fails', () {
      final aWord = word(900, 'あい', [a, i]);
      final aKana = kanaItem(id: 1);
      expect(aWord.isWord, isTrue);
      expect(aKana.isKana, isTrue);
      expect(() => aWord.kana, throwsA(isA<TypeError>()));
      expect(() => aKana.word, throwsA(isA<TypeError>()));
    });

    test('word prompts need no voice and are not typed', () {
      for (final type in CompleteLesson.wordPromptTypes) {
        expect(type.isForWord, isTrue);
        expect(type.needsAudio, isFalse);
        expect(type.isTyped, isFalse);
      }
      expect(PromptType.charToSoundChoice.isForWord, isFalse);
    });
  });

  group('the next word lesson', () {
    const getNext = GetNextWordLesson();

    test('a word is available once all its kana are introduced', () {
      final items = [
        ...kana(),
        word(900, 'あい', [a, i]),
        word(901, 'あか', [a, ka]),
      ];
      expect(
        getNext(items: items, now: now).map((w) => w.word.reading),
        ['あい'],
      );
    });

    test('nothing is offered before any kana is known', () {
      final items = [...kana(introduced: 0), word(900, 'あい', [a, i])];
      expect(getNext(items: items, now: now), isEmpty);
    });

    test('a word with a mark waits for the mark', () {
      Item mark({DateTime? introducedAt}) => Item(
            id: 50,
            kind: ItemKind.kana,
            key: 'hiragana:sokuon',
            sortOrder: 300,
            payload: const KanaPayload(
              character: 'っ',
              script: KanaScript.hiragana,
              romaji: 'small tsu',
              group: KanaGroup.mark,
            ),
            introducedAt: introducedAt,
          );
      final withMark = word(900, 'あっい', [a, 'hiragana:sokuon', i]);
      expect(getNext(items: [...kana(), mark(), withMark], now: now), isEmpty);
      expect(
        getNext(
          items: [...kana(), mark(introducedAt: earlier), withMark],
          now: now,
        ),
        hasLength(1),
      );
    });

    test('a lesson is the first five available words in order', () {
      final items = [
        ...kana(),
        for (var n = 0; n < 8; n++) word(900 + n, 'あい$n', [a, i]),
      ];
      final lesson = getNext(items: items, now: now);
      expect(lesson.map((w) => w.id), [900, 901, 902, 903, 904]);
    });

    test('a learned word is not offered again', () {
      final items = [
        ...kana(),
        word(900, 'あい', [a, i], introducedAt: earlier),
        word(901, 'うえ', [u, e]),
      ];
      expect(getNext(items: items, now: now).map((w) => w.id), [901]);
    });

    test('five words today use up the quota', () {
      final items = [
        ...kana(),
        for (var n = 0; n < 5; n++)
          word(900 + n, 'あい$n', [a, i], introducedAt: now),
        word(910, 'うえ', [u, e]),
      ];
      expect(getNext(items: items, now: now), isEmpty);
      final tomorrow = now.add(const Duration(days: 1));
      expect(getNext(items: items, now: tomorrow), hasLength(1));
    });

    test('part of the quota leaves a smaller lesson', () {
      final items = [
        ...kana(),
        for (var n = 0; n < 3; n++)
          word(900 + n, 'あい$n', [a, i], introducedAt: now),
        for (var n = 0; n < 6; n++) word(910 + n, 'うえ$n', [u, e]),
      ];
      expect(getNext(items: items, now: now), hasLength(2));
    });

    test('kana learned today do not use the word quota', () {
      final items = [
        ...kanaItems(hiraganaCount: 10, introduced: 5, introducedAt: now),
        word(900, 'あい', [a, i]),
      ];
      expect(getNext(items: items, now: now), hasLength(1));
    });

    test('few available words give a short lesson', () {
      final items = [
        ...kana(),
        word(900, 'あい', [a, i]),
        word(901, 'うえ', [u, e]),
      ];
      expect(getNext(items: items, now: now), hasLength(2));
    });

    test('a word dropped from the list is not offered', () {
      final items = [
        ...kana(),
        word(900, 'あい', [a, i]),
        word(901, 'うえ', [u, e]),
      ];
      final lesson =
          getNext(items: items, now: now, currentKeys: {'word:901'});
      expect(lesson.map((w) => w.id), [901]);
    });
  });

  group('completing a lesson', () {
    test('words get their two cards', () async {
      final words = [word(900, 'あい', [a, i]), word(901, 'うえ', [u, e])];
      final items = FakeItemRepository([...kana(), ...words]);
      final cards = FakeCardRepository();
      final completeLesson = CompleteLesson(
        itemRepository: items,
        cardRepository: cards,
        unitOfWork: FakeUnitOfWork(),
        scheduler: FakeScheduler(),
      );

      await completeLesson(items: words, now: now);

      final saved = await items.getItems();
      expect(
        saved.where((item) => item.isWord && item.introducedAt == now),
        hasLength(2),
      );
      final created = await cards.getCards();
      expect(created, hasLength(4));
      expect(
        created.where((c) => c.itemId == 900).map((c) => c.promptType),
        unorderedEquals([
          PromptType.wordToMeaningChoice,
          PromptType.meaningToWordChoice,
        ]),
      );
    });

    test('three correct answers to a word card create no typed card',
        () async {
      final cards = FakeCardRepository([
        reviewCard(
          id: 1,
          itemId: 900,
          promptType: PromptType.wordToMeaningChoice,
          consecutiveCorrect: 2,
        ),
      ]);
      final gradeAnswer = GradeAnswer(
        cardRepository: cards,
        reviewRepository: FakeReviewRepository(),
        unitOfWork: FakeUnitOfWork(),
        scheduler: FakeScheduler(),
      );

      final saved = await gradeAnswer(
        card: (await cards.getCards()).single,
        wasCorrect: true,
        now: now,
      );

      expect(saved.consecutiveCorrect, 3);
      expect(await cards.getCards(), hasLength(1));
    });
  });

  group('choices for a word card', () {
    const build = BuildWordChoiceOptions();

    List<Item> options(Item correct, List<Item> all, {int seed = 1}) =>
        build(correct: correct, allItems: all, random: Random(seed));

    test('four choices, one of them the answer', () {
      final correct = word(900, 'あい', [a, i], introducedAt: earlier);
      final all = [
        ...kana(),
        correct,
        for (var n = 1; n < 6; n++)
          word(900 + n, 'うえ$n', [u, e], introducedAt: earlier),
      ];
      final result = options(correct, all);
      expect(result, hasLength(4));
      expect(result.where((o) => o.id == 900), hasLength(1));
      expect(result.every((o) => o.isWord), isTrue);
    });

    test('a word read the same is never a wrong choice', () {
      final rain = word(900, 'あめ', [a], written: '雨', introducedAt: earlier);
      final candy =
          word(901, 'あめ', [a], written: '飴', introducedAt: earlier);
      final all = [
        ...kana(),
        rain,
        candy,
        for (var n = 2; n < 5; n++)
          word(900 + n, 'うえ$n', [u, e], introducedAt: earlier),
      ];
      for (var seed = 0; seed < 20; seed++) {
        expect(options(rain, all, seed: seed).map((o) => o.id),
            isNot(contains(901)));
      }
    });

    test('a word sharing a meaning is never a wrong choice', () {
      final father = word(900, 'ちち', [a],
          meanings: ['father'], introducedAt: earlier);
      final dad = word(901, 'おとうさん', [o],
          meanings: ['Father', 'dad'], introducedAt: earlier);
      final all = [
        ...kana(),
        father,
        dad,
        for (var n = 2; n < 5; n++)
          word(900 + n, 'うえ$n', [u, e], introducedAt: earlier),
      ];
      for (var seed = 0; seed < 20; seed++) {
        expect(options(father, all, seed: seed).map((o) => o.id),
            isNot(contains(901)));
      }
    });

    test('known words of the same type are preferred', () {
      final correct = word(900, 'あう', [a, u],
          partOfSpeech: 'verb', introducedAt: earlier);
      final all = [
        ...kana(),
        correct,
        for (var n = 1; n <= 3; n++)
          word(900 + n, 'いう$n', [i, u],
              partOfSpeech: 'verb', introducedAt: earlier),
        for (var n = 4; n <= 9; n++)
          word(900 + n, 'うえ$n', [u, e], introducedAt: earlier),
      ];
      for (var seed = 0; seed < 10; seed++) {
        final result = options(correct, all, seed: seed);
        expect(result.every((o) => o.word.partOfSpeech == 'verb'), isTrue);
      }
    });

    test('known words come before words not yet learned', () {
      final correct = word(900, 'あい', [a, i], introducedAt: earlier);
      final all = [
        ...kana(),
        correct,
        word(901, 'うえ', [u, e], introducedAt: earlier),
        word(902, 'おう', [o, u], partOfSpeech: 'verb', introducedAt: earlier),
        for (var n = 3; n < 9; n++) word(900 + n, 'いえ$n', [i, e]),
      ];
      for (var seed = 0; seed < 10; seed++) {
        final ids = options(correct, all, seed: seed).map((o) => o.id);
        expect(ids, containsAll([901, 902]));
      }
    });

    test('with few known words, readable ones fill the gap before others',
        () {
      final correct = word(900, 'あい', [a, i], introducedAt: earlier);
      final all = [
        ...kana(),
        correct,
        word(901, 'うえ', [u, e]),
        word(902, 'おう', [o, u]),
        word(903, 'いえ', [i, e]),
        for (var n = 4; n < 9; n++) word(900 + n, 'かか$n', [ka]),
      ];
      for (var seed = 0; seed < 10; seed++) {
        final ids = options(correct, all, seed: seed).map((o) => o.id);
        expect(ids, unorderedEquals([900, 901, 902, 903]));
      }
    });

    test('the words of the lesson being taken count as known', () {
      final lesson = [
        for (var n = 0; n < 4; n++) word(900 + n, 'あい$n', [a, i]),
      ];
      final all = [
        ...kana(),
        ...lesson,
        for (var n = 4; n < 9; n++) word(900 + n, 'うえ$n', [u, e]),
      ];
      final result = build(
        correct: lesson.first,
        allItems: all,
        random: Random(3),
        alsoKnown: lesson,
      );
      expect(result.map((o) => o.id), unorderedEquals([900, 901, 902, 903]));
    });

    test('there are four choices even when nothing else is readable', () {
      final correct = word(900, 'あい', [a, i], introducedAt: earlier);
      final all = [
        ...kana(),
        correct,
        for (var n = 1; n < 5; n++) word(900 + n, 'かか$n', [ka]),
      ];
      expect(options(correct, all), hasLength(4));
    });

    test('the choices vary between presentations', () {
      final correct = word(900, 'あい', [a, i], introducedAt: earlier);
      final all = [
        ...kana(),
        correct,
        for (var n = 1; n < 12; n++)
          word(900 + n, 'うえ$n', [u, e], introducedAt: earlier),
      ];
      final seen = {
        for (var seed = 0; seed < 10; seed++)
          (options(correct, all, seed: seed).map((o) => o.id).toList()..sort())
              .join(','),
      };
      expect(seen.length, greaterThan(1));
    });
  });

  group('words stay out of kana', () {
    final learnedWords = [
      for (var n = 0; n < 6; n++)
        wordItem(
          id: 900 + n,
          reading: 'あい$n',
          kanaKeys: const [a, i],
          introducedAt: earlier,
        ),
    ];
    final newWords = [
      for (var n = 0; n < 6; n++)
        wordItem(id: 950 + n, reading: 'うえ$n', kanaKeys: const [u, e]),
    ];

    test('a kana lesson never contains a word', () {
      final items = [...kana(), ...learnedWords, ...newWords];
      final lesson =
          const GetNextLesson()(items: items, goal: null, now: now);
      expect(lesson, isNotEmpty);
      expect(lesson.every((item) => item.isKana), isTrue);
    });

    test('words learned today do not use the kana quota', () {
      final wordsToday = [
        for (var n = 0; n < 5; n++)
          wordItem(
            id: 900 + n,
            reading: 'あい$n',
            kanaKeys: const [a, i],
            introducedAt: now,
          ),
      ];
      final without = const GetNextLesson()(
        items: kana(),
        goal: null,
        now: now,
      );
      final withWords = const GetNextLesson()(
        items: [...kana(), ...wordsToday],
        goal: null,
        now: now,
      );
      expect(withWords.map((i) => i.id), without.map((i) => i.id));
    });

    test('kana choices never contain a word', () {
      final items = [...kana(introduced: 10), ...learnedWords];
      final result = const BuildChoiceOptions()(
        correct: items.first,
        allItems: items,
        random: Random(1),
      );
      expect(result.every((item) => item.isKana), isTrue);
    });

    test('goal progress counts kana only', () {
      final items = [...kana(), ...learnedWords];
      final cards = [
        reviewCard(id: 1, itemId: 1),
        reviewCard(
          id: 2,
          itemId: 900,
          promptType: PromptType.wordToMeaningChoice,
        ),
      ];
      final reviews = [
        reviewRecord(id: 1, cardId: 1, reviewedAt: earlier),
        // A wrong answer on a word must not lower the kana accuracy.
        reviewRecord(id: 2, cardId: 2, reviewedAt: earlier, wasCorrect: false),
      ];
      final progress = const GetGoalProgress()(
        goal: goal(createdAt: earlier),
        items: items,
        cards: cards,
        reviews: reviews,
        now: now,
      );
      expect(progress.introducedCount, 5);
      expect(progress.totalCount, 10);
      expect(progress.accuracy, 1);
      expect(progress.status, GoalStatus.active);
    });

    test('a day with only a word lesson keeps the streak', () {
      final items = [
        ...kanaItems(hiraganaCount: 5, introduced: 5, introducedAt: earlier),
        wordItem(id: 900, reading: 'あい', introducedAt: now),
      ];
      final streak =
          const GetStudyStats().streak(items: items, reviews: [], now: now);
      expect(streak, 1);
    });

    test('kana status is not asked of words', () {
      // The kana grid is the only caller, and it lists kana only; this
      // pins the status of a kana next to learned words.
      expect(
        const GetKanaStatus()(kana().first, const []),
        KanaStatus.learning,
      );
    });
  });
}
