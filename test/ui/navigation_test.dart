import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/main.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  Future<FakeDependencies> pumpApp(WidgetTester tester) async {
    final deps = FakeDependencies(items: kanaItems(hiraganaCount: 12));
    await tester.pumpWidget(IppoApp(dependencies: deps.app));
    await tester.pumpAndSettle();
    return deps;
  }

  testWidgets('first launch offers a goal, then a lesson', (tester) async {
    await pumpApp(tester);

    expect(find.text('Set your first goal'), findsOneWidget);

    await tester.tap(find.text('Start with this goal'));
    await tester.pumpAndSettle();

    expect(find.text('Set your first goal'), findsNothing);
    expect(find.text('14 days left'), findsOneWidget);
    expect(find.text('Learn 5 new kana'), findsOneWidget);
  });

  testWidgets('a lesson runs from the home screen and back', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Start with this goal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start lesson'));
    await tester.pumpAndSettle();
    expect(find.text('New kana 1 of 5'), findsOneWidget);
    expect(find.text('あ'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start the quiz'));
    await tester.pumpAndSettle();
    expect(find.text('How is this read?'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Start lesson'), findsOneWidget);
  });

  testWidgets('completing a lesson makes reviews available', (tester) async {
    final deps = await pumpApp(tester);
    await tester.tap(find.text('Start with this goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start lesson'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start the quiz'));
    await tester.pumpAndSettle();

    const readings = {'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o'};
    while (find.text('How is this read?').evaluate().isNotEmpty) {
      final shown = readings.keys
          .firstWhere((kana) => find.text(kana).evaluate().isNotEmpty);
      await tester.tap(find.widgetWithText(FilledButton, readings[shown]!));
      await tester.pumpAndSettle();
    }
    expect(find.text('Lesson complete'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(await deps.cards.getCards(), hasLength(10));
    expect(find.text('10 cards are due'), findsOneWidget);

    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Review  0 / 10'), findsOneWidget);
  });

  testWidgets('the kana grid opens a kana\'s detail', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Kana'));
    await tester.pumpAndSettle();
    expect(find.text('Hiragana'), findsOneWidget);
    expect(find.text('0 known, 0 learning, 12 not started'), findsOneWidget);

    await tester.tap(find.text('か'));
    await tester.pumpAndSettle();
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Write my own'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hiragana'), findsOneWidget);
  });

  testWidgets('settings and goal screens open from home', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Daily review limit'), findsOneWidget);
    expect(find.text('Daily reminder'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adjust the goal'));
    await tester.pumpAndSettle();
    expect(find.text('New goal'), findsOneWidget);

    await tester.tap(find.text('Start this goal'));
    await tester.pumpAndSettle();
    expect(find.text('14 days left'), findsOneWidget);
  });
}
