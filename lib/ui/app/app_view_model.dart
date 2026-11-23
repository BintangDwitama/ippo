import 'dart:async';

import 'package:ippo/data/repositories/launch_appearance_repository.dart';
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
    this._launchAppearance,
  }) : _uiState = AppUiState(appearanceMode: initialAppearanceMode) {
    _reportLaunchAppearance(initialAppearanceMode);
    _subscription = settingsRepository.getAppearanceModeStream().listen((mode) {
      if (mode == _uiState.appearanceMode) return;
      _uiState = AppUiState(appearanceMode: mode);
      _reportLaunchAppearance(mode);
      notify();
    });
  }

  final LaunchAppearanceRepository? _launchAppearance;

  /// Keeps the launch screen, which the system draws before the app
  /// runs, in step with the chosen appearance. Said again at every
  /// start: the setting may have come back with a restored backup.
  void _reportLaunchAppearance(AppearanceMode mode) {
    unawaited(
      _launchAppearance?.setLaunchBrightness(LaunchBrightness.forMode(mode)),
    );
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
