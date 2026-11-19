import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/ui/app/app_view_model.dart';
import 'package:ippo/ui/settings/settings_view_model.dart';

import '../fakes/fake_repositories.dart';
import '../support/fake_dependencies.dart';

void main() {
  group('AppViewModel', () {
    test('starts with the appearance it is given', () {
      final settings = FakeSettingsRepository()
        ..appearanceMode = AppearanceMode.paper;
      final viewModel = AppViewModel(
        settings,
        initialAppearanceMode: AppearanceMode.paper,
      );
      addTearDown(viewModel.dispose);

      expect(viewModel.uiState.appearanceMode, AppearanceMode.paper);
    });

    test('follows changes to the stored appearance', () async {
      final settings = FakeSettingsRepository();
      final viewModel = AppViewModel(settings);
      addTearDown(viewModel.dispose);
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      await pumpEventQueue();
      expect(viewModel.uiState.appearanceMode, AppearanceMode.automatic);
      expect(notifications, 0);

      await settings.setAppearanceMode(AppearanceMode.night);
      await pumpEventQueue();

      expect(viewModel.uiState.appearanceMode, AppearanceMode.night);
      expect(notifications, 1);
    });
  });

  group('SettingsViewModel appearance', () {
    test('loads the stored appearance', () async {
      final deps = FakeDependencies();
      deps.settings.appearanceMode = AppearanceMode.night;
      final viewModel = SettingsViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();

      expect(viewModel.uiState.appearanceMode, AppearanceMode.night);
    });

    test('stores a new appearance and shows it as selected', () async {
      final deps = FakeDependencies();
      final viewModel = SettingsViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      expect(viewModel.uiState.appearanceMode, AppearanceMode.automatic);

      await viewModel.setAppearanceMode(AppearanceMode.paper);

      expect(viewModel.uiState.appearanceMode, AppearanceMode.paper);
      expect(deps.settings.appearanceMode, AppearanceMode.paper);
    });
  });
}
