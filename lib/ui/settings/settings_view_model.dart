import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/speech_speed.dart';
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
  bool _voiceDownloadUnavailable = false;

  SettingsUiState _uiState = const SettingsUiState();
  SettingsUiState get uiState => _uiState;

  Future<void> _load() async {
    _uiState = SettingsUiState(
      isLoading: false,
      dailyReviewCap: await _deps.settingsRepository.getDailyReviewCap(),
      reminderTime: await _deps.settingsRepository.getReminderTime(),
      isReminderPermissionDenied: _isPermissionDenied,
      // Asked afresh each time: the learner may have just downloaded
      // the voice.
      japaneseVoice: await _deps.speechRepository.getJapaneseVoice(),
      voiceDownloadUnavailable: _voiceDownloadUnavailable,
      appearanceMode: await _deps.settingsRepository.getAppearanceMode(),
      speechSpeed: await _deps.settingsRepository.getSpeechSpeed(),
    );
    notify();
  }

  /// Reads the settings again, for when another screen changed them.
  Future<void> reload() => _load();

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

  /// Stores the chosen appearance. The app itself restyles by observing
  /// the setting, not through this ViewModel.
  Future<void> setAppearanceMode(AppearanceMode mode) async {
    await _deps.settingsRepository.setAppearanceMode(mode);
    await _load();
  }

  /// A few kana, spoken to let the learner judge the speaking speed.
  static const String speechSample = 'あ、か、さ';

  /// Stores the speaking speed and plays the sample at it, so one tap
  /// answers how the choice sounds.
  Future<void> setSpeechSpeed(SpeechSpeed speed) async {
    await _deps.settingsRepository.setSpeechSpeed(speed);
    await _load();
    await playSample();
  }

  /// Speaks the sample at the stored speed. Does nothing without a
  /// Japanese voice.
  Future<void> playSample() async {
    if (!_uiState.isJapaneseVoiceAvailable) return;
    await _deps.speechRepository.speak(speechSample);
  }

  /// Opens the phone's voice download screen. If the phone has none,
  /// the row then explains where to look instead.
  Future<void> openVoiceDownload() async {
    final opened = await _deps.speechRepository.openVoiceDownload();
    _voiceDownloadUnavailable = !opened;
    await _load();
  }

  Future<void> disableReminder() async {
    await _deps.reminderRepository.disableReminder();
    await _deps.settingsRepository.setReminderTime(null);
    _isPermissionDenied = false;
    await _load();
  }
}
