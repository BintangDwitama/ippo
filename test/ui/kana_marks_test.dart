import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/main.dart';
import 'package:ippo/ui/kana_grid/kana_detail_view_model.dart';
import 'package:ippo/ui/lesson/lesson_ui_state.dart';
import 'package:ippo/ui/lesson/lesson_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';
import '../support/seed_items.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 2, 9);

  bool isHiragana(KanaPayload k) => k.script == KanaScript.hiragana;

  /// A learner who has every hiragana except the small っ.
  FakeDependencies beforeHiraganaMark() => FakeDependencies(
    items: seedKanaItems(
      introduced: (k) => isHiragana(k) && !k.isMark,
      introducedAt: earlier,
    ),
    now: now,
  );

  /// A learner who has every kana except the two katakana marks.
  FakeDependencies beforeKatakanaMarks() => FakeDependencies(
    items: seedKanaItems(
      introduced: (k) => !k.isMark || isHiragana(k),
      introducedAt: earlier,
    ),
    now: now,
  );

  group('LessonViewModel with marks', () {
    Future<LessonViewModel> create(FakeDependencies deps) async {
      final viewModel = LessonViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('presents a mark with its rule and speaks the sample pair', () async {
      final deps = beforeHiraganaMark();
      final viewModel = await create(deps);

      final state = viewModel.uiState as LessonPresenting;
      expect(state.item.kana.character, 'っ');
      expect(state.total, 1);
      expect(state.isLast, isTrue);
      expect(state.hasQuiz, isFalse);
      expect(deps.speech.spoken, ['きて、きって']);
    });

    test('replaying the sound speaks the pair again', () async {
      final deps = beforeHiraganaMark();
      final viewModel = await create(deps);

      viewModel.replaySound();

      expect(deps.speech.spoken, ['きて、きって', 'きて、きって']);
    });

    test('a lesson of one mark completes without a quiz or cards', () async {
      final deps = beforeHiraganaMark();
      final viewModel = await create(deps);

      viewModel.showNext();
      await pumpEventQueue();

      final state = viewModel.uiState as LessonComplete;
      expect(charactersOf(state.items), ['っ']);
      expect(state.hasReviewCards, isFalse);
      expect(kanaOf(await deps.items.getItems(), 'っ').introducedAt, now);
      expect(await deps.cards.getCards(), isEmpty);
    });

    test('the two katakana marks are presented in turn, then done', () async {
      final deps = beforeKatakanaMarks();
      final viewModel = await create(deps);

      final first = viewModel.uiState as LessonPresenting;
      expect(first.item.kana.character, 'ッ');
      expect(first.total, 2);
      expect(first.isLast, isFalse);
      expect(first.hasQuiz, isFalse);

      viewModel.showNext();
      final second = viewModel.uiState as LessonPresenting;
      expect(second.item.kana.character, 'ー');
      expect(second.isLast, isTrue);
      expect(deps.speech.spoken, ['カト、カット', 'ビル、ビール']);

      viewModel.showNext();
      await pumpEventQueue();

      expect(viewModel.uiState, isA<LessonComplete>());
      final items = await deps.items.getItems();
      expect(kanaOf(items, 'ッ').isIntroduced, isTrue);
      expect(kanaOf(items, 'ー').isIntroduced, isTrue);
      expect(await deps.cards.getCards(), isEmpty);
    });

    test('an ordinary lesson still has a quiz and creates cards', () async {
      final deps = FakeDependencies(items: seedKanaItems(), now: now);
      final viewModel = await create(deps);

      final presenting = viewModel.uiState as LessonPresenting;
      expect(presenting.hasQuiz, isTrue);
      expect(deps.speech.spoken, ['あ']);
      for (var i = 0; i < 5; i++) {
        viewModel.showNext();
      }
      expect(viewModel.uiState, isA<LessonQuiz>());
      expect((viewModel.uiState as LessonQuiz).total, 5);

      while (viewModel.uiState is LessonQuiz) {
        final quiz = viewModel.uiState as LessonQuiz;
        await viewModel.answer(quiz.item);
      }

      final complete = viewModel.uiState as LessonComplete;
      expect(complete.hasReviewCards, isTrue);
      expect(await deps.cards.getCards(), hasLength(10));
    });
  });

  test('the kana detail screen speaks a mark\'s sample pair', () async {
    final items = seedKanaItems();
    final deps = FakeDependencies(items: items, now: now);
    final viewModel = KanaDetailViewModel(
      deps.app,
      itemId: kanaOf(items, 'ー').id,
    );
    addTearDown(viewModel.dispose);
    await pumpEventQueue();

    viewModel.playSound();

    expect(deps.speech.spoken, ['ビル、ビール']);
  });

  group('screens', () {
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

    Future<void> bringIntoView(WidgetTester tester, Finder target) async {
      await tester.scrollUntilVisible(
        target,
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }

    FakeDependencies withExtendedGoal(FakeDependencies Function() base) {
      final source = base();
      return FakeDependencies(
        items: seedKanaItems(
          introduced: (k) => k.script == KanaScript.hiragana && !k.isMark,
          introducedAt: earlier,
        ),
        goal: goal(
          createdAt: now.subtract(const Duration(days: 1)),
          targetSet: GoalTargetSet.hiraganaExtended,
        ),
        now: source.now,
      );
    }

    testWidgets('a marks lesson runs from home to completion with no quiz', (
      tester,
    ) async {
      final deps = await pumpApp(tester, withExtendedGoal(beforeHiraganaMark));

      await bringIntoView(tester, find.text('Start lesson'));
      expect(find.text('っ'), findsOneWidget);
      await tester.tap(find.text('Start lesson'));
      await tester.pumpAndSettle();

      expect(find.text('New kana 1 of 1'), findsOneWidget);
      expect(find.text('small tsu'), findsOneWidget);
      expect(find.text('Start the quiz'), findsNothing);
      expect(deps.speech.spoken, ['きて、きって']);

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson complete'), findsOneWidget);
      expect(find.text('You learned っ.'), findsOneWidget);
      expect(find.textContaining('in your reviews'), findsNothing);
      expect(find.text('How is this read?'), findsNothing);
      expect(await deps.cards.getCards(), isEmpty);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('59 of 59 kana introduced'), findsOneWidget);
    });

    testWidgets('the grid shows a Marks section with the learned mark known', (
      tester,
    ) async {
      final deps = FakeDependencies(
        items: seedKanaItems(
          introduced: (k) => k.character == 'っ',
          introducedAt: earlier,
        ),
        now: now,
      );
      await pumpApp(tester, deps);

      await tester.tap(find.byTooltip('Kana'));
      await tester.pumpAndSettle();
      expect(find.text('1 known, 0 learning, 104 not started'), findsOneWidget);

      await bringIntoView(tester, find.text('Marks'));
      await bringIntoView(tester, find.text('っ'));
      expect(find.text('small tsu'), findsOneWidget);

      await tester.tap(find.text('っ'));
      await tester.pumpAndSettle();
      expect(find.text('Known'), findsOneWidget);
      expect(find.textContaining('mnemonic'), findsWidgets);
    });

    for (final mode in [
      AppearanceMode.daylight,
      AppearanceMode.night,
      AppearanceMode.paper,
    ]) {
      testWidgets('marks fit a small screen with large text in ${mode.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // Any overflow raises an error, which fails the test.
        await pumpApp(tester, beforeKatakanaMarks(), mode: mode);

        // The lesson preview with two marks, then the lesson itself.
        await bringIntoView(tester, find.text('Start lesson'));
        await tester.tap(find.text('Start lesson'));
        await tester.pumpAndSettle();
        expect(find.text('New kana 1 of 2'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(find.text('long mark'), findsOneWidget);
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();
        expect(find.text('Lesson complete'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // The katakana grid's last section.
        await tester.tap(find.byTooltip('Kana'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Katakana'));
        await tester.pumpAndSettle();
        await bringIntoView(tester, find.text('Marks'));
        await bringIntoView(tester, find.text('ー'));
        await tester.tap(find.text('ー'));
        await tester.pumpAndSettle();
        expect(find.text('Known'), findsOneWidget);
      });
    }
  });
}
