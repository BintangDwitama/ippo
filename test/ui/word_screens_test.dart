import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/word_list_info.dart';
import 'package:ippo/main.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:ippo/ui/home/home_ui_state.dart';
import 'package:ippo/ui/home/home_view_model.dart';
import 'package:ippo/ui/review/review_ui_state.dart';
import 'package:ippo/ui/review/review_view_model.dart';
import 'package:ippo/ui/word_lesson/word_lesson_ui_state.dart';
import 'package:ippo/ui/word_lesson/word_lesson_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';
import '../support/seed_items.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 2, 9);
  final due = now.subtract(const Duration(hours: 1)).toUtc();

  const a = 'hiragana:a';
  const i = 'hiragana:i';
  const u = 'hiragana:u';
  const e = 'hiragana:e';
  const o = 'hiragana:o';
  const ka = 'hiragana:ka';

  /// Words readable with the あ row, and one that needs か.
  List<Item> words({int introduced = 0, DateTime? introducedAt}) {
    final specs = [
      ('あい', '愛', ['love'], [a, i], 'noun'),
      ('いえ', '家', ['house', 'home'], [i, e], 'noun'),
      ('うえ', '上', ['above', 'on top'], [u, e], 'noun'),
      ('あう', '会う', ['to meet'], [a, u], 'verb'),
      ('いう', '言う', ['to say'], [i, u], 'verb'),
      ('おおい', '多い', ['many', 'numerous'], [o, i], 'i-adjective'),
      ('いいえ', null, ['no'], [i, e], 'other'),
      ('あおい', '青い', ['blue'], [a, o, i], 'i-adjective'),
      ('あか', '赤', ['red'], [a, ka], 'noun'),
    ];
    return [
      for (var n = 0; n < specs.length; n++)
        wordItem(
          id: 900 + n,
          reading: specs[n].$1,
          written: specs[n].$2,
          meanings: specs[n].$3,
          kanaKeys: specs[n].$4,
          partOfSpeech: specs[n].$5,
          introducedAt: n < introduced ? (introducedAt ?? earlier) : null,
        ),
    ];
  }

  /// The あ row learned on an earlier day; the rest of the kana not.
  List<Item> kana({int introduced = 5}) => kanaItems(
    hiraganaCount: 10,
    introduced: introduced,
    introducedAt: earlier,
  );

  group('word lesson', () {
    Future<WordLessonViewModel> create(FakeDependencies deps) async {
      final viewModel = WordLessonViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    FakeDependencies learner({bool voice = true}) => FakeDependencies(
      items: [...kana(), ...words()],
      now: now,
      japaneseVoiceAvailable: voice,
    );

    void skipToCheck(WordLessonViewModel viewModel) {
      while (viewModel.uiState is WordLessonPresenting) {
        viewModel.showNext();
      }
    }

    Future<void> finishCheck(WordLessonViewModel viewModel) async {
      while (viewModel.uiState is WordLessonCheck) {
        final state = viewModel.uiState as WordLessonCheck;
        await viewModel.answer(state.item);
      }
    }

    test('is unavailable before any kana is known', () async {
      final viewModel = await create(
        FakeDependencies(items: [...kana(introduced: 0), ...words()], now: now),
      );
      expect(viewModel.uiState, isA<WordLessonUnavailable>());
    });

    test('presents the first word and speaks its reading', () async {
      final deps = learner();
      final viewModel = await create(deps);

      final state = viewModel.uiState as WordLessonPresenting;
      expect(state.item.word.reading, 'あい');
      expect(state.index, 0);
      expect(state.total, 5);
      expect(state.isFirst, isTrue);
      // The reading, not the kanji.
      expect(deps.speech.spoken, ['あい']);
    });

    test('goes forward and back through the words', () async {
      final deps = learner();
      final viewModel = await create(deps);

      viewModel.showNext();
      expect(
        (viewModel.uiState as WordLessonPresenting).item.word.reading,
        'いえ',
      );
      viewModel.showPrevious();
      final state = viewModel.uiState as WordLessonPresenting;
      expect(state.item.word.reading, 'あい');
      expect(deps.speech.spoken, ['あい', 'いえ', 'あい']);

      // Going back from the first word does nothing.
      viewModel.showPrevious();
      expect((viewModel.uiState as WordLessonPresenting).index, 0);
    });

    test('replays the word on request', () async {
      final deps = learner();
      final viewModel = await create(deps);
      viewModel.replaySound();
      expect(deps.speech.spoken, ['あい', 'あい']);
    });

    test(
      'without a voice nothing is spoken and the lesson still runs',
      () async {
        final deps = learner(voice: false);
        final viewModel = await create(deps);

        expect(
          (viewModel.uiState as WordLessonPresenting).voiceAvailable,
          isFalse,
        );
        skipToCheck(viewModel);
        await finishCheck(viewModel);
        expect(viewModel.uiState, isA<WordLessonComplete>());
        expect(deps.speech.spoken, isEmpty);
      },
    );

    test(
      'the check asks every word with four meanings to choose from',
      () async {
        final viewModel = await create(learner());
        skipToCheck(viewModel);

        final state = viewModel.uiState as WordLessonCheck;
        expect(state.total, 5);
        expect(state.answered, 0);
        expect(state.options, hasLength(4));
        expect(state.options.where((o) => o.id == state.item.id), hasLength(1));
        // The other choices are words of this same lesson.
        expect(state.options.every((o) => o.id >= 900 && o.id <= 904), isTrue);
      },
    );

    test('a wrong answer shows the word and asks it again later', () async {
      final deps = learner();
      final viewModel = await create(deps);
      skipToCheck(viewModel);
      final first = viewModel.uiState as WordLessonCheck;
      final wrong = first.options.firstWhere((o) => o.id != first.item.id);

      await viewModel.answer(wrong);

      final feedback = viewModel.uiState as WordLessonFeedback;
      expect(feedback.item.id, first.item.id);
      expect(feedback.chosen.id, wrong.id);
      expect(deps.speech.spoken.last, first.item.word.reading);
      expect(await deps.cards.getCards(), isEmpty);

      viewModel.continueAfterFeedback();
      final next = viewModel.uiState as WordLessonCheck;
      expect(next.item.id, isNot(first.item.id));
      expect(next.answered, 0);

      await finishCheck(viewModel);
      expect(viewModel.uiState, isA<WordLessonComplete>());
    });

    test('finishing introduces the words and creates two cards each', () async {
      final deps = learner();
      final viewModel = await create(deps);
      skipToCheck(viewModel);
      await finishCheck(viewModel);

      final complete = viewModel.uiState as WordLessonComplete;
      expect(complete.items, hasLength(5));
      final items = await deps.items.getItems();
      expect(
        items.where((x) => x.isWord && x.introducedAt == now),
        hasLength(5),
      );
      final cards = await deps.cards.getCards();
      expect(cards, hasLength(10));
      expect(cards.every((c) => c.promptType.isForWord), isTrue);
      // No answer of the check counts as a review.
      expect(await deps.reviews.getReviews(), isEmpty);
    });

    test('leaving before the end introduces nothing', () async {
      final deps = learner();
      final viewModel = await create(deps);
      skipToCheck(viewModel);
      final state = viewModel.uiState as WordLessonCheck;
      await viewModel.answer(state.item);

      expect(
        (await deps.items.getItems()).where((x) => x.isWord && x.isIntroduced),
        isEmpty,
      );
      expect(await deps.cards.getCards(), isEmpty);
    });

    test('a word dropped from the list is not taught', () async {
      final deps = FakeDependencies(
        items: [...kana(), ...words()],
        now: now,
        wordListInfo: const WordListInfo(
          dictionaryDate: '2026-11-16',
          keys: {'word:901', 'word:902'},
        ),
      );
      final viewModel = await create(deps);
      expect((viewModel.uiState as WordLessonPresenting).total, 2);
    });
  });

  group('reviewing words', () {
    Future<ReviewViewModel> create(FakeDependencies deps) async {
      final viewModel = ReviewViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    FakeDependencies withCards(List<ReviewCard> cards, {bool voice = true}) =>
        FakeDependencies(
          items: [...kana(), ...words(introduced: 8)],
          cards: cards,
          now: now,
          japaneseVoiceAvailable: voice,
        );

    ReviewCard wordCard(int id, int itemId, PromptType type) =>
        reviewCard(id: id, itemId: itemId, promptType: type, due: due);

    test(
      'a word-to-meaning card offers four words to choose a meaning from',
      () async {
        final deps = withCards([
          wordCard(1, 903, PromptType.wordToMeaningChoice),
        ]);
        final viewModel = await create(deps);

        final state = viewModel.uiState as ReviewQuestion;
        expect(state.item.word.reading, 'あう');
        expect(state.promptType, PromptType.wordToMeaningChoice);
        expect(state.options, hasLength(4));
        expect(state.options.every((o) => o.isWord), isTrue);
        // The only other verb learned is preferred.
        expect(state.options.map((o) => o.id), contains(904));
        // Nothing is spoken with the question.
        expect(deps.speech.spoken, isEmpty);
        viewModel.replaySound();
        expect(deps.speech.spoken, isEmpty);
      },
    );

    test(
      'a correct answer shows the word, speaks it and is graded good',
      () async {
        final deps = withCards([
          wordCard(1, 900, PromptType.meaningToWordChoice),
          wordCard(2, 901, PromptType.wordToMeaningChoice),
        ]);
        final viewModel = await create(deps);
        final question = viewModel.uiState as ReviewQuestion;

        await viewModel.answerChoice(question.item);

        final feedback = viewModel.uiState as ReviewFeedback;
        expect(feedback.wasCorrect, isTrue);
        expect(feedback.item.id, question.item.id);
        expect(feedback.mnemonic, isNull);
        expect(deps.speech.spoken, [question.item.word.reading]);
        final reviews = await deps.reviews.getReviews();
        expect(reviews.single.wasCorrect, isTrue);

        viewModel.continueAfterFeedback();
        final next = viewModel.uiState as ReviewQuestion;
        expect(next.item.id, isNot(question.item.id));
        expect(next.reviewed, 1);
      },
    );

    test(
      'a wrong answer says what was chosen and brings the card back',
      () async {
        final deps = withCards([
          wordCard(1, 900, PromptType.wordToMeaningChoice),
        ]);
        final viewModel = await create(deps);
        final question = viewModel.uiState as ReviewQuestion;
        final wrong = question.options.firstWhere((o) => o.id != 900);

        await viewModel.answerChoice(wrong);

        final feedback = viewModel.uiState as ReviewFeedback;
        expect(feedback.wasCorrect, isFalse);
        expect(feedback.givenAnswer, wrong.word.meaningText);
        expect(deps.speech.spoken, ['あい']);
        expect((await deps.reviews.getReviews()).single.wasCorrect, isFalse);

        viewModel.continueAfterFeedback();
        final again = viewModel.uiState as ReviewQuestion;
        expect(again.item.id, 900);
        expect(again.isRepeat, isTrue);
      },
    );

    test(
      'for meaning to word, the answer given is shown as a reading',
      () async {
        final deps = withCards([
          wordCard(1, 900, PromptType.meaningToWordChoice),
        ]);
        final viewModel = await create(deps);
        final question = viewModel.uiState as ReviewQuestion;
        final wrong = question.options.firstWhere((o) => o.id != 900);

        await viewModel.answerChoice(wrong);

        expect(
          (viewModel.uiState as ReviewFeedback).givenAnswer,
          wrong.word.reading,
        );
      },
    );

    test('word cards are reviewed without a Japanese voice', () async {
      final deps = withCards([
        wordCard(1, 900, PromptType.wordToMeaningChoice),
      ], voice: false);
      final viewModel = await create(deps);
      final question = viewModel.uiState as ReviewQuestion;

      await viewModel.answerChoice(question.item);

      final feedback = viewModel.uiState as ReviewFeedback;
      expect(feedback.voiceAvailable, isFalse);
      expect(deps.speech.spoken, isEmpty);
    });

    test('kana and word cards share one session', () async {
      final deps = withCards([
        reviewCard(id: 1, itemId: 1, due: due),
        reviewCard(id: 2, itemId: 2, due: due),
        wordCard(3, 900, PromptType.wordToMeaningChoice),
        wordCard(4, 900, PromptType.meaningToWordChoice),
      ]);
      final viewModel = await create(deps);

      final seen = <int>[];
      while (viewModel.uiState is! ReviewSummary) {
        final state = viewModel.uiState;
        if (state is ReviewQuestion) {
          seen.add(state.item.id);
          await viewModel.answerChoice(state.item);
        } else {
          viewModel.continueAfterFeedback();
        }
      }
      expect(seen, hasLength(4));
      expect(seen.toSet(), {1, 2, 900});
      // The two cards of the word are not asked back to back.
      final first = seen.indexOf(900);
      expect(seen[first + 1], isNot(900));
      expect((viewModel.uiState as ReviewSummary).reviewed, 4);
    });
  });

  group('home', () {
    Future<HomeUiState> stateOf(FakeDependencies deps) async {
      final viewModel = HomeViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel.uiState;
    }

    /// Kana whose daily lesson is done: the あ row learned today.
    List<Item> kanaDoneToday() =>
        kanaItems(hiraganaCount: 10, introduced: 5, introducedAt: now);

    test('reviews come first, with both lessons offered below', () async {
      final state = await stateOf(
        FakeDependencies(
          items: [...kana(), ...words()],
          cards: [reviewCard(id: 1, itemId: 1, due: due)],
          goal: goal(createdAt: earlier),
          now: now,
        ),
      );
      expect(state.primaryAction, HomePrimaryAction.review);
      expect(state.lessonSize, greaterThan(0));
      expect(state.nextLessonWords, ['あい', 'いえ', 'うえ', 'あう', 'いう']);
    });

    test('a kana lesson comes before a word lesson', () async {
      final state = await stateOf(
        FakeDependencies(
          items: [...kana(), ...words()],
          goal: goal(createdAt: earlier),
          now: now,
        ),
      );
      expect(state.primaryAction, HomePrimaryAction.lesson);
      expect(state.wordLessonSize, 5);
    });

    test('the word lesson is the step when kana are done for today', () async {
      final state = await stateOf(
        FakeDependencies(
          items: [...kanaDoneToday(), ...words()],
          goal: goal(createdAt: earlier),
          now: now,
        ),
      );
      expect(state.lessonSize, 0);
      expect(state.primaryAction, HomePrimaryAction.wordLesson);
    });

    test('with nothing left the learner rests', () async {
      final state = await stateOf(
        FakeDependencies(
          items: [
            ...kanaDoneToday(),
            ...words(introduced: 5, introducedAt: now),
          ],
          goal: goal(createdAt: earlier),
          now: now,
        ),
      );
      expect(state.wordLessonSize, 0);
      expect(state.primaryAction, HomePrimaryAction.rest);
    });

    test('learning words does not change goal progress', () async {
      final state = await stateOf(
        FakeDependencies(
          items: [...kana(), ...words(introduced: 5)],
          goal: goal(createdAt: earlier),
          now: now,
        ),
      );
      expect(state.progress!.introducedCount, 5);
      expect(state.progress!.totalCount, 10);
    });
  });

  group('on screen', () {
    Future<FakeDependencies> pumpApp(
      WidgetTester tester,
      FakeDependencies deps, {
      AppearanceMode mode = AppearanceMode.automatic,
    }) async {
      deps.settings.appearanceMode = mode;
      await tester.pumpWidget(
        IppoApp(dependencies: deps.app, initialAppearanceMode: mode),
      );
      await tester.pumpAndSettle();
      return deps;
    }

    Future<void> bringIntoView(
      WidgetTester tester,
      Finder target, {
      Finder? scrollable,
    }) async {
      await tester.scrollUntilVisible(
        target,
        120,
        scrollable: scrollable ?? find.byType(Scrollable).last,
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }

    /// The About screen's own list. Its addresses are selectable text,
    /// each of which holds a scrollable of its own.
    Finder aboutList() => find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;

    /// The real kana with the あ row learned today, so the kana lesson is
    /// done and the word lesson is the step.
    FakeDependencies wordLearner({List<ReviewCard> cards = const []}) {
      return FakeDependencies(
        items: [
          ...seedKanaItems(
            introduced: (k) => 'あいうえお'.contains(k.character),
            introducedAt: now,
          ),
          ...words(),
        ],
        cards: cards,
        goal: goal(createdAt: earlier),
        now: now,
        wordListInfo: WordListInfo(
          dictionaryDate: '2026-11-16',
          keys: {for (final w in words()) w.key},
        ),
      );
    }

    testWidgets('a word lesson runs from the home screen to the end', (
      tester,
    ) async {
      final deps = await pumpApp(tester, wordLearner());

      expect(find.text('Word lesson'), findsOneWidget);
      expect(find.text('5 new words'), findsOneWidget);
      expect(find.text('あい'), findsOneWidget);

      await bringIntoView(tester, find.text('Start word lesson'));
      await tester.tap(find.text('Start word lesson'));
      await tester.pumpAndSettle();
      expect(find.text('New word 1 of 5'), findsOneWidget);
      expect(find.text('love'), findsOneWidget);
      expect(find.text('noun'), findsOneWidget);
      expect(find.byType(WordText), findsOneWidget);
      expect(find.text('愛'), findsOneWidget);
      expect(find.text('Back'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('house; home'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('New word 1 of 5'), findsOneWidget);

      for (var n = 0; n < 4; n++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Start the check'));
      await tester.pumpAndSettle();
      expect(find.text('What does this mean?'), findsOneWidget);
      expect(find.byType(MeaningChoice), findsNWidgets(4));

      // Answer each question by the meaning of the word shown.
      final all = {for (final w in words()) w.word.reading: w.word};
      for (var n = 0; n < 5; n++) {
        final shown = tester.widget<WordText>(find.byType(WordText)).word;
        await tester.tap(
          find.widgetWithText(FilledButton, all[shown.reading]!.meaningText),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Lesson complete'), findsOneWidget);
      expect(await deps.cards.getCards(), hasLength(10));

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      // Today's five are used up; the cards are now due.
      expect(find.text('Word lesson'), findsNothing);
      expect(find.text('cards to review'), findsOneWidget);
    });

    testWidgets('a wrong answer in the check shows the word in full', (
      tester,
    ) async {
      await pumpApp(tester, wordLearner());
      await bringIntoView(tester, find.text('Start word lesson'));
      await tester.tap(find.text('Start word lesson'));
      await tester.pumpAndSettle();
      for (var n = 0; n < 4; n++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Start the check'));
      await tester.pumpAndSettle();

      final all = {for (final w in words()) w.word.reading: w.word};
      final shown = tester.widget<WordText>(find.byType(WordText)).word;
      final right = all[shown.reading]!.meaningText;
      final wrong = tester
          .widgetList<MeaningChoice>(find.byType(MeaningChoice))
          .firstWhere((c) => c.text != right);
      await tester.tap(find.widgetWithText(FilledButton, wrong.text));
      await tester.pumpAndSettle();

      expect(find.text('Not quite'), findsOneWidget);
      expect(find.text('You chose "${wrong.text}".'), findsOneWidget);
      expect(find.text(right), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('What does this mean?'), findsOneWidget);
    });

    testWidgets('a review shows word cards in both directions', (tester) async {
      final items = [
        ...seedKanaItems(
          introduced: (k) => 'あいうえお'.contains(k.character),
          introducedAt: earlier,
        ),
        ...words(introduced: 8),
      ];
      await pumpApp(
        tester,
        FakeDependencies(
          items: items,
          cards: [
            reviewCard(
              id: 1,
              itemId: 900,
              promptType: PromptType.wordToMeaningChoice,
              due: due,
            ),
            reviewCard(
              id: 2,
              itemId: 901,
              promptType: PromptType.meaningToWordChoice,
              due: due,
            ),
          ],
          goal: goal(createdAt: earlier),
          now: now,
        ),
      );
      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();

      for (var n = 0; n < 2; n++) {
        if (find.text('What does this mean?').evaluate().isNotEmpty) {
          expect(find.byType(WordText), findsOneWidget);
          expect(find.text('愛'), findsOneWidget);
          expect(find.byType(MeaningChoice), findsNWidgets(4));
          await tester.tap(find.widgetWithText(FilledButton, 'love'));
        } else {
          expect(find.text('Which word means this?'), findsOneWidget);
          expect(find.text('house; home'), findsOneWidget);
          expect(find.byType(WordLine), findsNWidgets(4));
          final right = find.byWidgetPredicate(
            (w) => w is WordLine && w.word.reading == 'いえ',
          );
          await tester.tap(right);
        }
        await tester.pumpAndSettle();
        expect(find.text('Correct'), findsOneWidget);
        expect(find.byType(WordDetail), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Session complete'), findsOneWidget);
    });

    testWidgets('the About screen credits the dictionary with its date', (
      tester,
    ) async {
      await pumpApp(tester, wordLearner());
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await bringIntoView(tester, find.text('About and sources'));
      await tester.tap(find.text('About and sources'));
      await tester.pumpAndSettle();

      expect(find.textContaining('JMdict dictionary file'), findsOneWidget);
      expect(
        find.textContaining(
          'Electronic Dictionary Research and Development Group',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('2026-11-16'), findsOneWidget);
      expect(find.textContaining('CC BY-SA 4.0'), findsWidgets);
      expect(
        find.text(
          'https://www.edrdg.org/wiki/index.php/'
          'JMdict-EDICT_Dictionary_Project',
        ),
        findsOneWidget,
      );
      expect(
        find.text('https://www.edrdg.org/edrdg/licence.html'),
        findsOneWidget,
      );
      await bringIntoView(
        tester,
        find.textContaining('compiled by Jonathan Waller'),
        scrollable: aboutList(),
      );
      expect(find.textContaining('Stephen Kraus'), findsOneWidget);
      await bringIntoView(
        tester,
        find.text(
          'https://github.com/BintangDwitama/ippo/tree/main/data/words',
        ),
        scrollable: aboutList(),
      );

      await bringIntoView(
        tester,
        find.text('Licences'),
        scrollable: aboutList(),
      );
      await tester.tap(find.text('Licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    for (final mode in [
      AppearanceMode.daylight,
      AppearanceMode.night,
      AppearanceMode.paper,
    ]) {
      testWidgets('word screens fit a small screen with large text in '
          '${mode.name}', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // The longest reading and the longest meanings in the real list
        // are about this size. Any overflow fails the test.
        final long = [
          wordItem(
            id: 900,
            reading: 'アクセサリーおおいいえ',
            written: '多い家多い家多い家',
            meanings: const [
              'traditional Japanese inn',
              'suffix for a familiar person\'s name',
              'place where things are sold',
            ],
            kanaKeys: const [a],
            partOfSpeech: 'na-adjective',
          ),
          for (var n = 1; n < 5; n++)
            wordItem(
              id: 900 + n,
              reading: 'あいうえおあいうえお$n',
              written: '愛愛愛愛愛愛',
              meanings: [
                'a rather long meaning number $n',
                'and a second one that is long too $n',
                'and a third to fill the button $n',
              ],
              kanaKeys: const [a],
            ),
        ];
        final deps = FakeDependencies(
          items: [
            ...seedKanaItems(
              introduced: (k) => 'あいうえお'.contains(k.character),
              introducedAt: now,
            ),
            ...long,
          ],
          goal: goal(createdAt: earlier),
          now: now,
        );
        await pumpApp(tester, deps, mode: mode);
        await bringIntoView(tester, find.text('Start word lesson'));
        await bringIntoView(tester, find.text('Start word lesson'));
        await tester.tap(find.text('Start word lesson'));
        await tester.pumpAndSettle();
        for (var n = 0; n < 4; n++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Start the check'));
        await tester.pumpAndSettle();
        expect(find.byType(MeaningChoice), findsNWidgets(4));

        // A wrong answer, to see the feedback, then finish.
        final vm = tester
            .widgetList<MeaningChoice>(find.byType(MeaningChoice))
            .toList();
        final shown = tester.widget<WordText>(find.byType(WordText)).word;
        final wrong = vm.firstWhere((c) => c.text != shown.meaningText);
        await tester.tap(find.widgetWithText(FilledButton, wrong.text));
        await tester.pumpAndSettle();
        expect(find.text('Not quite'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        for (var n = 0; n < 5; n++) {
          final word = tester.widget<WordText>(find.byType(WordText)).word;
          await tester.tap(find.widgetWithText(FilledButton, word.meaningText));
          await tester.pumpAndSettle();
        }
        expect(find.text('Lesson complete'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // The ten new cards, in both directions. The home list was
        // scrolled down to reach the lesson; go back to its top.
        await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start review'));
        await tester.pumpAndSettle();
        for (var n = 0; n < 10; n++) {
          final lines = find.byType(WordLine);
          if (lines.evaluate().isNotEmpty) {
            await tester.tap(lines.first);
          } else {
            await tester.tap(find.byType(MeaningChoice).first);
          }
          await tester.pumpAndSettle();
          expect(find.byType(WordDetail), findsOneWidget);
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
          if (find.text('Session complete').evaluate().isNotEmpty) break;
        }

        // And the About screen.
        while (find.byTooltip('Settings').evaluate().isEmpty) {
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await bringIntoView(tester, find.text('About and sources'));
        await tester.tap(find.text('About and sources'));
        await tester.pumpAndSettle();
        await bringIntoView(
          tester,
          find.text('Licences'),
          scrollable: aboutList(),
        );
      });
    }
  });
}
