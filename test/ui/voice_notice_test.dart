import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/japanese_voice.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/main.dart';
import 'package:ippo/ui/home/home_view_model.dart';
import 'package:ippo/ui/settings/settings_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 2, 9);

  FakeDependencies learner(JapaneseVoice voice, {bool withListening = false}) {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 10, introduced: 5, introducedAt: earlier),
      cards: [
        if (withListening)
          reviewCard(
            id: 1,
            itemId: 1,
            promptType: PromptType.soundToCharChoice,
            due: now.subtract(const Duration(hours: 1)).toUtc(),
          ),
      ],
      goal: goal(createdAt: earlier),
      now: now,
    );
    deps.speech.voice = voice;
    return deps;
  }

  group('home', () {
    Future<HomeViewModel> create(FakeDependencies deps) async {
      final viewModel = HomeViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('says nothing when the voice is downloaded', () async {
      final viewModel = await create(learner(JapaneseVoice.ready));
      expect(viewModel.uiState.voiceNotice, isNull);
      expect(viewModel.uiState.showVoiceNotice, isFalse);
    });

    test('warns when the voice is not downloaded, and listening still works',
        () async {
      final viewModel = await create(
        learner(JapaneseVoice.onlineOnly, withListening: true),
      );
      expect(viewModel.uiState.voiceNotice, JapaneseVoice.onlineOnly);
      // The listening card is still offered.
      expect(viewModel.uiState.dueCount, 1);
    });

    test('warns when there is no voice, and listening is paused', () async {
      final viewModel = await create(
        learner(JapaneseVoice.missing, withListening: true),
      );
      expect(viewModel.uiState.voiceNotice, JapaneseVoice.missing);
      expect(viewModel.uiState.dueCount, 0);
    });

    test('the notice goes when the voice has been downloaded', () async {
      final deps = learner(JapaneseVoice.onlineOnly);
      final viewModel = await create(deps);
      expect(viewModel.uiState.showVoiceNotice, isTrue);

      // The learner downloads the voice and comes back to the app.
      deps.speech.voice = JapaneseVoice.ready;
      await viewModel.refresh();

      expect(viewModel.uiState.showVoiceNotice, isFalse);
    });

    test('listening cards return once a missing voice is installed', () async {
      final deps = learner(JapaneseVoice.missing, withListening: true);
      final viewModel = await create(deps);
      expect(viewModel.uiState.dueCount, 0);

      deps.speech.voice = JapaneseVoice.ready;
      await viewModel.refresh();

      expect(viewModel.uiState.dueCount, 1);
    });

    test('opening the download screen', () async {
      final deps = learner(JapaneseVoice.onlineOnly);
      final viewModel = await create(deps);

      await viewModel.openVoiceDownload();

      expect(deps.speech.voiceDownloadsOpened, 1);
      expect(viewModel.uiState.voiceDownloadUnavailable, isFalse);
    });

    test('says where to look when the phone has no download screen', () async {
      final deps = learner(JapaneseVoice.onlineOnly);
      deps.speech.canOpenVoiceDownload = false;
      final viewModel = await create(deps);

      await viewModel.openVoiceDownload();

      expect(viewModel.uiState.voiceDownloadUnavailable, isTrue);
      expect(viewModel.uiState.showVoiceNotice, isTrue);
    });

    test('a dismissed notice stays away, for either state', () async {
      final deps = learner(JapaneseVoice.onlineOnly);
      final viewModel = await create(deps);
      await viewModel.dismissVoiceNotice();
      expect(viewModel.uiState.showVoiceNotice, isFalse);

      deps.speech.voice = JapaneseVoice.missing;
      await viewModel.refresh();
      expect(viewModel.uiState.showVoiceNotice, isFalse);
    });
  });

  group('settings', () {
    Future<SettingsViewModel> create(FakeDependencies deps) async {
      final viewModel = SettingsViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('shows the state and notices a download on reload', () async {
      final deps = learner(JapaneseVoice.onlineOnly);
      final viewModel = await create(deps);
      expect(viewModel.uiState.japaneseVoice, JapaneseVoice.onlineOnly);
      // The sample can be played: an online voice still speaks.
      expect(viewModel.uiState.isJapaneseVoiceAvailable, isTrue);

      deps.speech.voice = JapaneseVoice.ready;
      await viewModel.reload();
      expect(viewModel.uiState.japaneseVoice, JapaneseVoice.ready);
    });

    test('opens the download screen, or says where to look', () async {
      final deps = learner(JapaneseVoice.missing);
      final viewModel = await create(deps);

      await viewModel.openVoiceDownload();
      expect(deps.speech.voiceDownloadsOpened, 1);
      expect(viewModel.uiState.voiceDownloadUnavailable, isFalse);

      deps.speech.canOpenVoiceDownload = false;
      await viewModel.openVoiceDownload();
      expect(viewModel.uiState.voiceDownloadUnavailable, isTrue);
    });
  });

  group('on screen', () {
    Future<void> pumpApp(
      WidgetTester tester,
      FakeDependencies deps, {
      AppearanceMode mode = AppearanceMode.automatic,
    }) async {
      deps.settings.appearanceMode = mode;
      await tester.pumpWidget(
        IppoApp(dependencies: deps.app, initialAppearanceMode: mode),
      );
      await tester.pumpAndSettle();
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

    testWidgets('the home notice explains an undownloaded voice and opens '
        'the download', (tester) async {
      final deps = learner(JapaneseVoice.onlineOnly);
      await pumpApp(tester, deps);

      expect(find.text('Japanese voice not downloaded'), findsOneWidget);
      expect(find.textContaining('missing without internet'), findsOneWidget);

      await tester.tap(find.text('Download voice'));
      await tester.pumpAndSettle();
      expect(deps.speech.voiceDownloadsOpened, 1);
      expect(find.textContaining('did not open'), findsNothing);

      // Back in the app with the voice downloaded: the next refresh
      // clears the notice. Opening and leaving settings refreshes home.
      deps.speech.voice = JapaneseVoice.ready;
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await bringIntoView(tester, find.text('Japanese voice'));
      expect(find.textContaining('Downloaded.'), findsOneWidget);
      expect(find.text('Download voice'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Japanese voice not downloaded'), findsNothing);
    });

    testWidgets('a phone without a download screen is told where to look', (
      tester,
    ) async {
      final deps = learner(JapaneseVoice.missing);
      deps.speech.canOpenVoiceDownload = false;
      await pumpApp(tester, deps);

      expect(find.text('No Japanese voice found'), findsOneWidget);
      await tester.tap(find.text('Download voice'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Install voice data'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('No Japanese voice found'), findsNothing);
    });

    testWidgets('settings keeps showing the state after the notice is '
        'dismissed', (tester) async {
      final deps = learner(JapaneseVoice.onlineOnly);
      deps.settings.voiceNoticeShown = true;
      await pumpApp(tester, deps);
      expect(find.text('Japanese voice not downloaded'), findsNothing);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await bringIntoView(tester, find.text('Japanese voice'));
      expect(find.textContaining('Not downloaded.'), findsOneWidget);
      await bringIntoView(tester, find.text('Download voice'));
      await tester.tap(find.text('Download voice'));
      await tester.pumpAndSettle();
      expect(deps.speech.voiceDownloadsOpened, 1);
    });

    for (final mode in [
      AppearanceMode.daylight,
      AppearanceMode.night,
      AppearanceMode.paper,
    ]) {
      for (final voice in [JapaneseVoice.onlineOnly, JapaneseVoice.missing]) {
        testWidgets('the ${voice.name} notice fits a small screen with large '
            'text in ${mode.name}', (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.view.reset);
          addTearDown(
            tester.platformDispatcher.clearTextScaleFactorTestValue,
          );

          // Any overflow raises an error, which fails the test.
          final deps = learner(voice);
          deps.speech.canOpenVoiceDownload = false;
          await pumpApp(tester, deps, mode: mode);
          await bringIntoView(tester, find.text('Download voice'));
          await tester.tap(find.text('Download voice'));
          await tester.pumpAndSettle();
          await bringIntoView(tester, find.text('Got it'));

          await tester.tap(find.byTooltip('Settings'));
          await tester.pumpAndSettle();
          await bringIntoView(tester, find.text('Download voice'));
          await tester.tap(find.text('Download voice'));
          await tester.pumpAndSettle();
          await bringIntoView(tester, find.text('Play a sample'));
        });
      }
    }
  });
}
