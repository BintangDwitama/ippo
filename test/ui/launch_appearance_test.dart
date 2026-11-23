import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/launch_appearance_repository.dart';
import 'package:ippo/data/repositories/method_channel_launch_appearance_repository.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/ui/app/app_view_model.dart';

import '../fakes/fake_repositories.dart';

/// Records what the system was told.
class FakeLaunchAppearanceRepository implements LaunchAppearanceRepository {
  final List<LaunchBrightness> reported = [];

  @override
  Future<void> setLaunchBrightness(LaunchBrightness brightness) async {
    reported.add(brightness);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each appearance has its launch screen', () {
    expect(
      LaunchBrightness.forMode(AppearanceMode.automatic),
      LaunchBrightness.system,
    );
    expect(
      LaunchBrightness.forMode(AppearanceMode.daylight),
      LaunchBrightness.light,
    );
    expect(LaunchBrightness.forMode(AppearanceMode.night), LaunchBrightness.dark);
    // Paper is a light theme; the system has no third choice.
    expect(
      LaunchBrightness.forMode(AppearanceMode.paper),
      LaunchBrightness.light,
    );
  });

  group('the app reports its appearance', () {
    test('at start, even when nothing changed', () {
      final launch = FakeLaunchAppearanceRepository();
      final viewModel = AppViewModel(
        FakeSettingsRepository()..appearanceMode = AppearanceMode.night,
        initialAppearanceMode: AppearanceMode.night,
        launchAppearance: launch,
      );
      addTearDown(viewModel.dispose);

      expect(launch.reported, [LaunchBrightness.dark]);
    });

    test('whenever the setting changes', () async {
      final settings = FakeSettingsRepository();
      final launch = FakeLaunchAppearanceRepository();
      final viewModel = AppViewModel(settings, launchAppearance: launch);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();

      await settings.setAppearanceMode(AppearanceMode.night);
      await pumpEventQueue();
      await settings.setAppearanceMode(AppearanceMode.paper);
      await pumpEventQueue();
      // Back to following the phone.
      await settings.setAppearanceMode(AppearanceMode.automatic);
      await pumpEventQueue();

      expect(launch.reported, [
        LaunchBrightness.system,
        LaunchBrightness.dark,
        LaunchBrightness.light,
        LaunchBrightness.system,
      ]);
    });

    test('works without anywhere to report to', () async {
      final settings = FakeSettingsRepository();
      final viewModel = AppViewModel(settings);
      addTearDown(viewModel.dispose);

      await settings.setAppearanceMode(AppearanceMode.night);
      await pumpEventQueue();

      expect(viewModel.uiState.appearanceMode, AppearanceMode.night);
    });
  });

  group('telling Android', () {
    const channel = MethodChannel(
      MethodChannelLaunchAppearanceRepository.channelName,
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const repository = MethodChannelLaunchAppearanceRepository();

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('sends light, dark or system', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

      for (final brightness in LaunchBrightness.values) {
        await repository.setLaunchBrightness(brightness);
      }

      expect(calls.map((c) => c.method).toSet(), {'setNightMode'});
      expect(calls.map((c) => c.arguments), ['light', 'dark', 'system']);
    });

    test('the Android side must understand what is sent', () {
      // MainActivity.kt compares against these words.
      expect(LaunchBrightness.values.map((b) => b.name), [
        'light',
        'dark',
        'system',
      ]);
    });

    test('does nothing where there is no Android side', () async {
      await repository.setLaunchBrightness(LaunchBrightness.dark);
    });

    test('a refusal by the system does not surface', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'denied');
      });
      await repository.setLaunchBrightness(LaunchBrightness.dark);
    });
  });
}
