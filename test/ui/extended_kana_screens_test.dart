import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/main.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';
import '../support/seed_items.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 2, 9);

  bool basicAndVoicedHiragana(KanaPayload k) =>
      k.script == KanaScript.hiragana && k.group != KanaGroup.combination;

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

  /// Scrolls the top screen until [target] is built and fully on screen.
  Future<void> bringIntoView(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  /// A learner who knows basic and voiced hiragana and is working on a
  /// goal for the voiced and combination ones.
  FakeDependencies combinationLearner({bool withDueCard = false}) {
    final items = seedKanaItems(
      introduced: basicAndVoicedHiragana,
      introducedAt: earlier,
    );
    return FakeDependencies(
      items: items,
      cards: [
        if (withDueCard)
          reviewCard(id: 1, itemId: kanaOf(items, 'が').id, due: now.toUtc()),
      ],
      goal: goal(
        createdAt: now.subtract(const Duration(days: 1)),
        targetSet: GoalTargetSet.hiraganaExtended,
      ),
      now: now,
    );
  }

  testWidgets('a lesson of two combination rows runs to its quiz', (
    tester,
  ) async {
    await pumpApp(tester, combinationLearner());

    expect(find.text('きゃ'), findsOneWidget);
    expect(find.text('しょ'), findsOneWidget);
    expect(find.text('6 new kana'), findsOneWidget);

    await tester.tap(find.text('Start lesson'));
    await tester.pumpAndSettle();
    expect(find.text('New kana 1 of 6'), findsOneWidget);
    expect(find.text('きゃ'), findsOneWidget);
    expect(find.text('kya'), findsOneWidget);
    // The fake mnemonic repository supplies placeholder text.
    expect(find.textContaining('mnemonic'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start the quiz'));
    await tester.pumpAndSettle();

    expect(find.text('How is this read?'), findsOneWidget);
    expect(find.byType(ChoiceGrid), findsOneWidget);
  });

  testWidgets('a review of が offers its partner and row-mates', (tester) async {
    await pumpApp(tester, combinationLearner(withDueCard: true));

    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    expect(find.text('が'), findsOneWidget);
    final choices = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ChoiceGrid),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data!)
        .toSet();
    expect(choices, hasLength(4));
    expect(choices, containsAll(['ga', 'ka']));
    expect(choices.difference({'ga', 'ka'}), everyElement(startsWith('g')));
  });

  testWidgets('the kana grid shows three sections', (tester) async {
    await pumpApp(tester, combinationLearner());

    await tester.tap(find.byTooltip('Kana'));
    await tester.pumpAndSettle();

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('1 known, 71 learning, 33 not started'), findsOneWidget);
    await bringIntoView(tester, find.text('Voiced'));
    expect(find.text('が'), findsOneWidget);
    await bringIntoView(tester, find.text('Combination'));
    await bringIntoView(tester, find.text('ぴょ'));

    await tester.tap(find.text('ぴょ'));
    await tester.pumpAndSettle();
    expect(find.text('pyo'), findsWidgets);
    expect(find.text('Not started'), findsOneWidget);
  });

  testWidgets('the goal screen lists six target sets with their sizes', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      FakeDependencies(items: seedKanaItems(), now: now),
    );

    await tester.tap(find.text('Adjust the goal'));
    await tester.pumpAndSettle();

    for (final title in [
      'Hiragana basics',
      'Hiragana voiced and combination',
      'Katakana basics',
      'Katakana voiced and combination',
      'Both basic sets',
      'All kana',
    ]) {
      await bringIntoView(tester, find.text(title));
      expect(find.text(title), findsOneWidget);
    }
    // Back to the top; the options above have scrolled out of view.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await bringIntoView(tester, find.text('Hiragana voiced and combination'));
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Hiragana voiced and combination'),
        matching: find.text('59 kana'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Hiragana voiced and combination'));
    await tester.pumpAndSettle();
    await bringIntoView(tester, find.text('Start this goal'));
    await tester.tap(find.text('Start this goal'));
    await tester.pumpAndSettle();

    final saved = (await deps.goals.getCurrentGoal())!;
    expect(saved.targetSet, GoalTargetSet.hiraganaExtended);
    expect(find.text('0 of 59 kana introduced'), findsOneWidget);
  });

  for (final mode in [
    AppearanceMode.daylight,
    AppearanceMode.night,
    AppearanceMode.paper,
  ]) {
    testWidgets('two-character kana fit a small screen in ${mode.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // Any overflow raises an error, which fails the test.
      final items = seedKanaItems(
        introduced: (k) => k.script == KanaScript.hiragana,
        introducedAt: earlier,
      );
      await pumpApp(
        tester,
        FakeDependencies(
          items: items,
          cards: [
            reviewCard(id: 1, itemId: kanaOf(items, 'きゃ').id, due: now.toUtc()),
          ],
          goal: goal(
            createdAt: now.subtract(const Duration(days: 1)),
            targetSet: GoalTargetSet.everything,
          ),
          now: now,
        ),
        mode: mode,
      );
      // Home: the next lesson is katakana; scroll through the screen.
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 900));
      await tester.pumpAndSettle();

      // A review question showing a two-character kana.
      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();
      final question = find.descendant(
        of: find.byType(KanaText),
        matching: find.text('きゃ'),
      );
      expect(question, findsOneWidget);
      // On one line: no taller than a single line at its font size.
      final size = tester.getSize(question);
      expect(size.height, lessThan(160 * 1.15 + 1));
      expect(size.width, greaterThan(size.height * 0.9));

      // Answer wrongly to reach the feedback, which shows it again.
      final choices = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ChoiceGrid),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data!)
          .toList();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          choices.firstWhere((c) => c != 'kya'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.textContaining('The answer is きゃ (kya)'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // The grid, down to the last combination row.
      await tester.tap(find.byTooltip('Kana'));
      await tester.pumpAndSettle();
      await bringIntoView(tester, find.text('Combination'));
      await bringIntoView(tester, find.text('ぴょ'));
      await tester.pageBack();
      await tester.pumpAndSettle();

      // The goal screen with its six options.
      await bringIntoView(tester, find.textContaining('days left'));
      await tester.tap(find.textContaining('days left'));
      await tester.pumpAndSettle();
      await bringIntoView(tester, find.text('All kana'));
      await bringIntoView(tester, find.text('Save changes'));
    });
  }
}
