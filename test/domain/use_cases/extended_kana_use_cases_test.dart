import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/use_cases/build_choice_options.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/domain/use_cases/get_next_lesson.dart';

import '../../support/builders.dart';
import '../../support/seed_items.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 2, 9);

  bool isHiragana(KanaPayload k) => k.script == KanaScript.hiragana;
  bool basicHiragana(KanaPayload k) =>
      isHiragana(k) && k.group == KanaGroup.basic;

  /// Basic hiragana whose teaching position is before [character].
  bool Function(KanaPayload) basicBefore(String character) {
    final order = [
      for (final item in seedKanaItems())
        if (basicHiragana(item.kana)) item.kana.character,
    ];
    final index = order.indexOf(character);
    return (k) => basicHiragana(k) && order.indexOf(k.character) < index;
  }

  group('GetNextLesson with the real kana', () {
    const getNextLesson = GetNextLesson();

    List<String> lesson({bool Function(KanaPayload)? introduced, Goal? goal}) {
      return charactersOf(
        getNextLesson(
          items: seedKanaItems(introduced: introduced, introducedAt: earlier),
          goal: goal,
          now: now,
        ),
      );
    }

    test('starts with the a row', () {
      expect(lesson(), ['あ', 'い', 'う', 'え', 'お']);
    });

    test('teaches a full row at a time', () {
      expect(lesson(introduced: basicBefore('か')), ['か', 'き', 'く', 'け', 'こ']);
    });

    test('does not merge the short ya row with the full ra row', () {
      expect(lesson(introduced: basicBefore('や')), ['や', 'ゆ', 'よ']);
      expect(lesson(introduced: basicBefore('ら')), ['ら', 'り', 'る', 'れ', 'ろ']);
    });

    test('teaches the last short rows together', () {
      expect(lesson(introduced: basicBefore('わ')), ['わ', 'を', 'ん']);
    });

    test('finishes a row left partly introduced, then adds short rows', () {
      // The old rule of five could leave る れ ろ behind.
      expect(lesson(introduced: basicBefore('る')), [
        'る',
        'れ',
        'ろ',
        'わ',
        'を',
        'ん',
      ]);
    });

    test('moves on to voiced hiragana after the basic ones', () {
      expect(lesson(introduced: basicHiragana), ['が', 'ぎ', 'ぐ', 'げ', 'ご']);
    });

    test('never mixes groups in one lesson', () {
      // Only ぽ's row is left in the voiced group; combination kana wait.
      bool allButPRow(KanaPayload k) =>
          basicHiragana(k) ||
          (isHiragana(k) && k.group == KanaGroup.voiced && k.row != 'p');

      expect(lesson(introduced: allButPRow), ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ']);
    });

    test('pairs combination rows', () {
      bool basicAndVoiced(KanaPayload k) =>
          isHiragana(k) && k.group != KanaGroup.combination;

      expect(lesson(introduced: basicAndVoiced), [
        'きゃ',
        'きゅ',
        'きょ',
        'しゃ',
        'しゅ',
        'しょ',
      ]);
    });

    test('teaches the last combination row alone', () {
      bool allButPy(KanaPayload k) => isHiragana(k) && k.row != 'py';

      expect(lesson(introduced: allButPy), ['ぴゃ', 'ぴゅ', 'ぴょ']);
    });

    test('starts katakana only when all hiragana are introduced', () {
      expect(lesson(introduced: isHiragana), ['ア', 'イ', 'ウ', 'エ', 'オ']);
    });

    test('never mixes scripts in one lesson', () {
      // One hiragana row of three left, then katakana.
      bool allButPy(KanaPayload k) => isHiragana(k) && k.row != 'py';

      final characters = lesson(introduced: allButPy);
      expect(characters, hasLength(3));
    });

    test('a basic hiragana goal offers nothing beyond its 46 kana', () {
      expect(
        lesson(
          introduced: basicHiragana,
          goal: goal(createdAt: now),
        ),
        isEmpty,
      );
    });

    test('a voiced and combination goal teaches only those kana', () {
      final extended = goal(
        createdAt: now,
        targetSet: GoalTargetSet.hiraganaExtended,
      );

      expect(lesson(introduced: basicHiragana, goal: extended), [
        'が',
        'ぎ',
        'ぐ',
        'げ',
        'ご',
      ]);
      // It does not go back for basic kana that were skipped.
      expect(lesson(goal: extended), ['が', 'ぎ', 'ぐ', 'げ', 'ご']);
    });

    test('a both-basics goal goes from basic hiragana to basic katakana', () {
      final both = goal(createdAt: now, targetSet: GoalTargetSet.both);

      expect(lesson(introduced: basicHiragana, goal: both), [
        'ア',
        'イ',
        'ウ',
        'エ',
        'オ',
      ]);
    });

    test('no lesson exceeds six kana anywhere on the path', () {
      final introducedKeys = <String>{};
      var lessons = 0;
      while (true) {
        final next = getNextLesson(
          items: seedKanaItems(
            introduced: (k) =>
                introducedKeys.contains('${k.script.name}:${k.character}'),
            introducedAt: earlier,
          ),
          goal: null,
          now: now,
        );
        if (next.isEmpty) break;
        expect(next.length, inInclusiveRange(1, GetNextLesson.maxBatchSize));
        expect(next.map((i) => i.kana.script).toSet(), hasLength(1));
        expect(next.map((i) => i.kana.group).toSet(), hasLength(1));
        for (final item in next) {
          introducedKeys.add('${item.kana.script.name}:${item.kana.character}');
        }
        lessons++;
      }

      expect(introducedKeys, hasLength(211));
      // Per script: 10 basic lessons, 5 voiced, 6 combination.
      expect(lessons, 44);
    });
  });

  group('GoalTargetSet', () {
    final kana = [for (final item in seedKanaItems()) item.kana];
    int count(GoalTargetSet target) => kana.where(target.includes).length;

    test('covers the right number of kana', () {
      expect(count(GoalTargetSet.hiragana), 46);
      expect(count(GoalTargetSet.katakana), 46);
      expect(count(GoalTargetSet.both), 92);
      expect(count(GoalTargetSet.hiraganaExtended), 59);
      expect(count(GoalTargetSet.katakanaExtended), 60);
      expect(count(GoalTargetSet.everything), 211);
    });

    test('basic and extended sets of a script do not overlap', () {
      for (final k in kana) {
        final sets = [
          GoalTargetSet.hiragana,
          GoalTargetSet.hiraganaExtended,
          GoalTargetSet.katakana,
          GoalTargetSet.katakanaExtended,
        ].where((target) => target.includes(k));
        expect(sets, hasLength(1), reason: k.character);
      }
    });

    test('suggests the next step of the path', () {
      expect(GoalTargetSet.hiragana.next, GoalTargetSet.hiraganaExtended);
      expect(GoalTargetSet.hiraganaExtended.next, GoalTargetSet.katakana);
      expect(GoalTargetSet.katakana.next, GoalTargetSet.katakanaExtended);
      expect(GoalTargetSet.katakanaExtended.next, isNull);
      expect(GoalTargetSet.both.next, GoalTargetSet.everything);
      expect(GoalTargetSet.everything.next, isNull);
    });

    test('goal progress counts only the kana of its target set', () {
      const getGoalProgress = GetGoalProgress();
      final items = seedKanaItems(
        introduced: basicHiragana,
        introducedAt: earlier,
      );
      int total(GoalTargetSet target) => getGoalProgress(
        goal: goal(createdAt: now, targetSet: target),
        items: items,
        cards: const [],
        reviews: const [],
        now: now,
      ).totalCount;
      int introduced(GoalTargetSet target) => getGoalProgress(
        goal: goal(createdAt: now, targetSet: target),
        items: items,
        cards: const [],
        reviews: const [],
        now: now,
      ).introducedCount;

      expect(total(GoalTargetSet.hiragana), 46);
      expect(introduced(GoalTargetSet.hiragana), 46);
      expect(total(GoalTargetSet.hiraganaExtended), 59);
      expect(introduced(GoalTargetSet.hiraganaExtended), 0);
      expect(total(GoalTargetSet.both), 92);
      expect(total(GoalTargetSet.everything), 211);
      expect(introduced(GoalTargetSet.everything), 46);
    });
  });

  group('BuildChoiceOptions with the real kana', () {
    const buildChoiceOptions = BuildChoiceOptions();

    List<String> options(
      String character, {
      required bool Function(KanaPayload) introduced,
      int seed = 1,
      List<String> lesson = const [],
    }) {
      final items = seedKanaItems(
        introduced: introduced,
        introducedAt: earlier,
      );
      final built = buildChoiceOptions(
        correct: kanaOf(items, character),
        allItems: items,
        random: Random(seed),
        preferred: [for (final c in lesson) kanaOf(items, c)],
      );
      expect(built, hasLength(4));
      expect(charactersOf(built), contains(character));
      expect(charactersOf(built).toSet(), hasLength(4));
      return charactersOf(built)..remove(character);
    }

    bool hiraganaUpTo(KanaPayload k, KanaGroup last) =>
        isHiragana(k) && k.group.index <= last.index;

    test('offers the unvoiced partner and the rest from the same row', () {
      for (var seed = 0; seed < 10; seed++) {
        final wrong = options(
          'が',
          introduced: (k) => hiraganaUpTo(k, KanaGroup.voiced),
          seed: seed,
        );

        expect(wrong, contains('か'));
        expect(
          wrong.where((c) => c != 'か'),
          everyElement(isIn(['ぎ', 'ぐ', 'げ', 'ご'])),
        );
      }
    });

    test('offers both partners of a kana with two', () {
      final wrong = options(
        'は',
        introduced: (k) => hiraganaUpTo(k, KanaGroup.voiced),
      );

      expect(wrong, containsAll(['ば', 'ぱ']));
      // The third is its look-alike.
      expect(wrong, contains('ほ'));
    });

    test('offers a look-alike before row-mates', () {
      for (var seed = 0; seed < 10; seed++) {
        final wrong = options('ぬ', introduced: basicHiragana, seed: seed);

        expect(wrong, contains('め'));
        expect(
          wrong.where((c) => c != 'め'),
          everyElement(isIn(['な', 'に', 'ね', 'の'])),
        );
      }
    });

    test('treats a look-alike listed on only one side as mutual', () {
      // の lists め; め is asked.
      final wrong = options('め', introduced: basicHiragana);

      expect(wrong, containsAll(['ぬ', 'の']));
    });

    test('offers the voiced partner of a combination kana and its row', () {
      final wrong = options('きゃ', introduced: isHiragana);

      expect(wrong, contains('ぎゃ'));
      expect(wrong.where((c) => c != 'ぎゃ'), everyElement(isIn(['きゅ', 'きょ'])));
    });

    test('never offers a partner the learner has not met', () {
      for (var seed = 0; seed < 10; seed++) {
        final wrong = options('か', introduced: basicHiragana, seed: seed);

        expect(wrong, isNot(contains('が')));
        expect(wrong, everyElement(isIn(['き', 'く', 'け', 'こ'])));
      }
    });

    test('never offers a kana with the same reading', () {
      for (var seed = 0; seed < 20; seed++) {
        expect(
          options('じ', introduced: isHiragana, seed: seed),
          isNot(contains('ぢ')),
        );
        expect(
          options('づ', introduced: isHiragana, seed: seed),
          isNot(contains('ず')),
        );
      }
    });

    test('never offers the other script', () {
      final wrong = options('ア', introduced: (_) => true);

      final katakana = {
        for (final item in seedKanaItems())
          if (item.kana.script == KanaScript.katakana) item.kana.character,
      };
      expect(wrong, everyElement(isIn(katakana)));
      expect(wrong, contains('マ'));
    });

    test('varies the options between presentations', () {
      final seen = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        seen.addAll(options('く', introduced: basicHiragana, seed: seed));
      }

      // く has no partner or look-alike yet, so all four row-mates turn up.
      expect(seen, {'か', 'き', 'け', 'こ'});
    });

    test('varies where the correct answer sits', () {
      final positions = <int>{};
      for (var seed = 0; seed < 30; seed++) {
        final items = seedKanaItems(introduced: basicHiragana);
        final built = buildChoiceOptions(
          correct: kanaOf(items, 'か'),
          allItems: items,
          random: Random(seed),
        );
        positions.add(charactersOf(built).indexOf('か'));
      }

      expect(positions, {0, 1, 2, 3});
    });

    test('uses the current lesson in the very first lesson', () {
      final wrong = options(
        'あ',
        introduced: (_) => false,
        lesson: ['あ', 'い', 'う', 'え', 'お'],
      );

      // お looks like あ; the rest are from the lesson's row.
      expect(wrong, contains('お'));
      expect(wrong, everyElement(isIn(['い', 'う', 'え', 'お'])));
    });

    test('falls back to the nearest kana when too few have been met', () {
      final wrong = options('あ', introduced: (_) => false, lesson: ['あ', 'い']);

      expect(wrong, contains('い'));
      expect(wrong, everyElement(isIn(['い', 'う', 'え', 'お'])));
    });
  });
}
