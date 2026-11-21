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
    this.isJapaneseVoiceAvailable = true,
    this.appearanceMode = AppearanceMode.automatic,
    this.speechSpeed = SpeechSpeed.fallback,
  });

  final bool isLoading;
  final int dailyReviewCap;

  /// The reminder time; null when the reminder is off.
  final ReminderTime? reminderTime;

  /// The learner tried to turn the reminder on but refused permission.
  final bool isReminderPermissionDenied;
  final bool isJapaneseVoiceAvailable;
  final AppearanceMode appearanceMode;
  final SpeechSpeed speechSpeed;

  bool get isReminderOn => reminderTime != null;
}
