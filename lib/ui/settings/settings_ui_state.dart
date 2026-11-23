import 'package:ippo/domain/models/japanese_voice.dart';
import 'package:flutter/foundation.dart';
import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/speech_speed.dart';

@immutable
class SettingsUiState {
  const SettingsUiState({
    this.isLoading = true,
    this.dailyReviewCap = SettingsRepository.defaultDailyReviewCap,
    this.reminderTime,
    this.isReminderPermissionDenied = false,
    this.japaneseVoice = JapaneseVoice.ready,
    this.voiceDownloadUnavailable = false,
    this.appearanceMode = AppearanceMode.automatic,
    this.speechSpeed = SpeechSpeed.fallback,
  });

  final bool isLoading;
  final int dailyReviewCap;

  /// The reminder time; null when the reminder is off.
  final ReminderTime? reminderTime;

  /// The learner tried to turn the reminder on but refused permission.
  final bool isReminderPermissionDenied;
  final JapaneseVoice japaneseVoice;

  /// The phone could not open its voice download screen.
  final bool voiceDownloadUnavailable;

  bool get isJapaneseVoiceAvailable => japaneseVoice.canSpeak;
  final AppearanceMode appearanceMode;
  final SpeechSpeed speechSpeed;

  bool get isReminderOn => reminderTime != null;
}
