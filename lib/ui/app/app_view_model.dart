import 'dart:async';

import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/ui/app/app_ui_state.dart';
import 'package:ippo/ui/core/view_model.dart';

/// Holds what the whole app depends on: the chosen appearance.
///
/// App-scoped, because every screen is drawn with its state. It follows
/// the stored setting, so any screen that changes the setting restyles
/// the app without knowing about this ViewModel.
class AppViewModel extends ViewModel {
  AppViewModel(
    SettingsRepository settingsRepository, {
    AppearanceMode initialAppearanceMode = AppearanceMode.automatic,
  }) : _uiState = AppUiState(appearanceMode: initialAppearanceMode) {
    _subscription = settingsRepository.getAppearanceModeStream().listen((mode) {
      if (mode == _uiState.appearanceMode) return;
      _uiState = AppUiState(appearanceMode: mode);
      notify();
    });
  }

  late final StreamSubscription<AppearanceMode> _subscription;

  AppUiState _uiState;
  AppUiState get uiState => _uiState;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
