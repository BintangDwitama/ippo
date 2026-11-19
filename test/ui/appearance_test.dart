import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/main.dart';
import 'package:ippo/ui/core/theme/app_themes.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);

  /// A learner part-way through: five kana introduced with cards due, a
  /// lesson available and an active goal.
  FakeDependencies learnerInProgress(AppearanceMode mode) {
    final deps = FakeDependencies(
      items: kanaItems(
        hiraganaCount: 12,
        introduced: 5,
        introducedAt: now.subtract(const Duration(days: 2)),
      ),
      cards: [
        for (var id = 1; id <= 5; id++)
          reviewCard(id: id, itemId: id, due: now.toUtc()),
      ],
      goal: goal(createdAt: now.subtract(const Duration(days: 2))),
      now: now,
    );
    deps.settings.appearanceMode = mode;
    return deps;
  }

  Future<FakeDependencies> pumpApp(
    WidgetTester tester, {
    AppearanceMode mode = AppearanceMode.automatic,
    FakeDependencies? dependencies,
  }) async {
    final deps = dependencies ?? learnerInProgress(mode);
    await tester.pumpWidget(
      IppoApp(dependencies: deps.app, initialAppearanceMode: mode),
    );
    await tester.pumpAndSettle();
    return deps;
  }

  /// The background colour of the screen on top, which identifies the
  /// theme in use.
  Color pageColor(WidgetTester tester) {
    return Theme.of(
      tester.element(find.byType(Scaffold).last),
    ).scaffoldBackgroundColor;
  }

  const fixedModes = {
    AppearanceMode.daylight: 'Daylight',
    AppearanceMode.night: 'Night',
    AppearanceMode.paper: 'Paper',
  };

  group('Appearance setting', () {
    testWidgets('lists four options with the current one selected', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      for (final title in ['Automatic', 'Daylight', 'Night', 'Paper']) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Automatic'),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );
    });

    testWidgets('choosing a theme restyles the app without a restart', (
      tester,
    ) async {
      final deps = await pumpApp(tester);
      expect(pageColor(tester), AppThemes.daylight.scaffoldBackgroundColor);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle();

      expect(deps.settings.appearanceMode, AppearanceMode.night);
      expect(pageColor(tester), AppThemes.night.scaffoldBackgroundColor);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Night'),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Start review'), findsOneWidget);
      expect(pageColor(tester), AppThemes.night.scaffoldBackgroundColor);
    });

    testWidgets('a fixed theme ignores the device\'s dark mode', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pumpApp(tester, mode: AppearanceMode.paper);

      expect(pageColor(tester), AppThemes.paper.scaffoldBackgroundColor);
    });

    testWidgets('Automatic follows the device between light and dark', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await pumpApp(tester);
      expect(pageColor(tester), AppThemes.night.scaffoldBackgroundColor);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();

      expect(pageColor(tester), AppThemes.daylight.scaffoldBackgroundColor);
    });

    testWidgets('the stored theme is used from the first frame', (
      tester,
    ) async {
      final deps = learnerInProgress(AppearanceMode.paper);
      await tester.pumpWidget(
        IppoApp(
          dependencies: deps.app,
          initialAppearanceMode: AppearanceMode.paper,
        ),
      );

      // No settling: this is the very first frame.
      expect(pageColor(tester), AppThemes.paper.scaffoldBackgroundColor);
    });
  });

  group('One layout in every theme', () {
    testWidgets('the home screen has the same texts and buttons', (
      tester,
    ) async {
      final texts = <String, List<String?>>{};
      final buttons = <String, int>{};
      for (final MapEntry(key: mode, value: name) in fixedModes.entries) {
        await pumpApp(tester, mode: mode);
        texts[name] = [
          for (final text in tester.widgetList<Text>(find.byType(Text)))
            text.data,
        ];
        buttons[name] = tester
            .widgetList(find.bySubtype<ButtonStyleButton>())
            .length;
        // Remove the app so the next theme starts from scratch.
        await tester.pumpWidget(const SizedBox.shrink());
      }

      expect(texts['Daylight'], contains('cards to review'));
      expect(texts['Daylight'], contains('Start lesson'));
      expect(texts['Night'], texts['Daylight']);
      expect(texts['Paper'], texts['Daylight']);
      expect(buttons['Night'], buttons['Daylight']);
      expect(buttons['Paper'], buttons['Daylight']);
    });

    for (final MapEntry(key: mode, value: name) in fixedModes.entries) {
      testWidgets('$name fits a small screen with large text', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // Any overflow raises an error, which fails the test.
        await pumpApp(tester, mode: mode);
        expect(find.text('cards to review'), findsOneWidget);
        expect(find.text('か'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(find.text('day streak'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, 900));
        await tester.pumpAndSettle();

        // A review question, answered wrongly to reach the feedback.
        await tester.tap(find.text('Start review'));
        await tester.pumpAndSettle();
        expect(find.text('How is this read?'), findsOneWidget);
        const readings = {'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o'};
        final shown = readings.keys.firstWhere(
          (kana) => find.text(kana).evaluate().isNotEmpty,
        );
        final choices = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(ChoiceGrid),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data!)
            .toList();
        expect(choices, hasLength(4));
        final wrong = choices.firstWhere((c) => c != readings[shown]);
        await tester.tap(find.widgetWithText(FilledButton, wrong));
        await tester.pumpAndSettle();

        expect(find.text('Not quite'), findsOneWidget);
        expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
        expect(
          find.textContaining('The answer is $shown (${readings[shown]})'),
          findsOneWidget,
        );

        await tester.pageBack();
        await tester.pumpAndSettle();

        // The kana grid.
        await tester.tap(find.byTooltip('Kana'));
        await tester.pumpAndSettle();
        expect(find.text('Hiragana'), findsOneWidget);
        expect(find.text('か'), findsOneWidget);

        expect(pageColor(tester), AppThemes.all[name]!.scaffoldBackgroundColor);
      });
    }
  });

  group('FeedbackBanner', () {
    Widget host({required bool disableAnimations}) {
      return MaterialApp(
        theme: AppThemes.daylight,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const Scaffold(
            body: FeedbackBanner(
              isCorrect: false,
              label: 'Not quite',
              detail: 'The answer is き (ki).',
            ),
          ),
        ),
      );
    }

    testWidgets('fades in by default', (tester) async {
      await tester.pumpWidget(host(disableAnimations: false));

      final opacity = find.descendant(
        of: find.byType(FeedbackBanner),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(opacity).opacity, 0);

      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(opacity).opacity, 1);
    });

    testWidgets('appears at once when the device reduces motion', (
      tester,
    ) async {
      await tester.pumpWidget(host(disableAnimations: true));

      expect(
        find.descendant(
          of: find.byType(FeedbackBanner),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(find.text('Not quite'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });
}
