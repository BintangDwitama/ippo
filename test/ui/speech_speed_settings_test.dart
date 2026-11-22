import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/speech_speed.dart';
import 'package:ippo/main.dart';
import 'package:ippo/ui/settings/settings_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  group('SettingsViewModel speaking speed', () {
    Future<SettingsViewModel> create(FakeDependencies deps) async {
      final viewModel = SettingsViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('shows slow by default', () async {
      final viewModel = await create(FakeDependencies());

      expect(viewModel.uiState.speechSpeed, SpeechSpeed.slow);
    });

    test('loads the stored speed', () async {
      final deps = FakeDependencies();
      deps.settings.speechSpeed = SpeechSpeed.normal;

      final viewModel = await create(deps);

      expect(viewModel.uiState.speechSpeed, SpeechSpeed.normal);
    });

    test('choosing a speed stores it and plays the sample', () async {
      final deps = FakeDependencies();
      final viewModel = await create(deps);

      await viewModel.setSpeechSpeed(SpeechSpeed.verySlow);

      expect(viewModel.uiState.speechSpeed, SpeechSpeed.verySlow);
      expect(deps.settings.speechSpeed, SpeechSpeed.verySlow);
      expect(deps.speech.spoken, [SettingsViewModel.speechSample]);
    });

    test('the sample can be played again', () async {
      final deps = FakeDependencies();
      final viewModel = await create(deps);

      await viewModel.playSample();
      await viewModel.playSample();

      expect(deps.speech.spoken, hasLength(2));
      expect(deps.speech.spoken.first, 'あ、か、さ');
    });

    test(
      'without a Japanese voice the speed is stored but nothing plays',
      () async {
        final deps = FakeDependencies(japaneseVoiceAvailable: false);
        final viewModel = await create(deps);

        await viewModel.setSpeechSpeed(SpeechSpeed.normal);
        await viewModel.playSample();

        expect(deps.settings.speechSpeed, SpeechSpeed.normal);
        expect(viewModel.uiState.speechSpeed, SpeechSpeed.normal);
        expect(deps.speech.spoken, isEmpty);
      },
    );

    test('changing the speed leaves the other settings as they were', () async {
      final deps = FakeDependencies();
      deps.settings.dailyReviewCap = 60;
      deps.settings.appearanceMode = AppearanceMode.paper;
      final viewModel = await create(deps);

      await viewModel.setSpeechSpeed(SpeechSpeed.normal);

      expect(viewModel.uiState.dailyReviewCap, 60);
      expect(viewModel.uiState.appearanceMode, AppearanceMode.paper);
    });
  });

  group('settings screen', () {
    Future<FakeDependencies> openSettings(
      WidgetTester tester, {
      AppearanceMode mode = AppearanceMode.automatic,
      bool voice = true,
    }) async {
      final deps = FakeDependencies(
        items: kanaItems(hiraganaCount: 12),
        japaneseVoiceAvailable: voice,
      );
      deps.settings.appearanceMode = mode;
      deps.settings.voiceNoticeShown = true;
      await tester.pumpWidget(
        IppoApp(dependencies: deps.app, initialAppearanceMode: mode),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
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

    Finder selectedIn(String title) => find.descendant(
      of: find.widgetWithText(ListTile, title),
      matching: find.byIcon(Icons.radio_button_checked),
    );

    testWidgets('offers three speeds with Slow selected', (tester) async {
      await openSettings(tester);

      await bringIntoView(tester, find.text('Speaking speed'));
      for (final title in ['Normal', 'Slow', 'Very slow']) {
        await bringIntoView(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
      }
      await bringIntoView(tester, find.text('Slow'));
      expect(selectedIn('Slow'), findsOneWidget);
      expect(selectedIn('Normal'), findsNothing);
    });

    testWidgets('choosing a speed selects it and plays the sample', (
      tester,
    ) async {
      final deps = await openSettings(tester);

      await bringIntoView(tester, find.text('Very slow'));
      await tester.tap(find.text('Very slow'));
      await tester.pumpAndSettle();

      expect(deps.settings.speechSpeed, SpeechSpeed.verySlow);
      expect(selectedIn('Very slow'), findsOneWidget);
      expect(selectedIn('Slow'), findsNothing);
      expect(deps.speech.spoken, ['あ、か、さ']);
    });

    testWidgets('the sample button plays the sample', (tester) async {
      final deps = await openSettings(tester);

      await bringIntoView(tester, find.text('Play a sample'));
      await tester.tap(find.text('Play a sample'));
      await tester.pumpAndSettle();

      expect(deps.speech.spoken, ['あ、か、さ']);
    });

    testWidgets('without a Japanese voice the sample button is disabled', (
      tester,
    ) async {
      final deps = await openSettings(tester, voice: false);

      await bringIntoView(tester, find.text('Play a sample'));
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Play a sample'),
          matching: find.bySubtype<OutlinedButton>(),
        ),
      );
      expect(button.onPressed, isNull);

      await bringIntoView(tester, find.text('Normal'));
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(deps.settings.speechSpeed, SpeechSpeed.normal);
      expect(deps.speech.spoken, isEmpty);
    });

    for (final mode in [
      AppearanceMode.daylight,
      AppearanceMode.night,
      AppearanceMode.paper,
    ]) {
      testWidgets('fits a small screen with large text in ${mode.name}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // Any overflow raises an error, which fails the test.
        await openSettings(tester, mode: mode);
        await bringIntoView(tester, find.text('Speaking speed'));
        await bringIntoView(tester, find.text('Very slow'));
        await bringIntoView(tester, find.text('Play a sample'));
        await bringIntoView(tester, find.text('About and sources'));
      });
    }
  });
}
