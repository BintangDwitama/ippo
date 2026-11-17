import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/settings/settings_ui_state.dart';

class SettingsViewModel extends ViewModel {
  SettingsViewModel(this._deps) {
    unawaited(_load());
  }

  static const ReminderTime defaultReminderTime =
      ReminderTime(hour: 19, minute: 0);

  final AppDependencies _deps;
  bool _isPermissionDenied = false;

  SettingsUiState _uiState = const SettingsUiState();
  SettingsUiState get uiState => _uiState;

  Future<void> _load() async {
    _uiState = SettingsUiState(
      isLoading: false,
      dailyReviewCap: await _deps.settingsRepository.getDailyReviewCap(),
      reminderTime: await _deps.settingsRepository.getReminderTime(),
      isReminderPermissionDenied: _isPermissionDenied,
      isJapaneseVoiceAvailable:
          await _deps.speechRepository.isJapaneseVoiceAvailable(),
    );
    notify();
  }

  Future<void> setDailyReviewCap(int cap) async {
    if (cap < 1) return;
    await _deps.settingsRepository.setDailyReviewCap(cap);
    await _load();
  }

  /// Turns the daily reminder on at [time]. If the learner refuses
  /// notification permission, the reminder stays off.
  Future<void> enableReminder(ReminderTime time) async {
    final granted = await _deps.reminderRepository.enableReminder(time);
    _isPermissionDenied = !granted;
    await _deps.settingsRepository.setReminderTime(granted ? time : null);
    await _load();
  }

  Future<void> disableReminder() async {
    await _deps.reminderRepository.disableReminder();
    await _deps.settingsRepository.setReminderTime(null);
    _isPermissionDenied = false;
    await _load();
  }
}
