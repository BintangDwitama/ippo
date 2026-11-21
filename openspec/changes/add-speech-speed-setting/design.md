## Context

`TtsService.speakJapanese` sets the device voice to a rate of 0.4 once and reuses it. `TtsSpeechRepository` is the only caller, and every screen that plays a sound goes through `SpeechRepository.speak(text)`: the lesson, review and kana detail ViewModels. Settings are key and value rows read and written through `SettingsRepository`.

On Android the speech plugin's rate of 0.5 is the voice's natural speed, so today's 0.4 is about 80% of natural.

## Goals / Non-Goals

**Goals:**
- The learner picks a speed by ear and it applies everywhere at once.
- No screen other than settings changes.
- The setting never travels to another phone.

**Non-Goals:**
- A continuous slider. Three named steps are easier to choose between and to test.
- Repeating a kana or a separate slow-replay control.
- Changing pitch or voice.

## Decisions

### 1. Three named speeds

```dart
enum SpeechSpeed {
  normal(0.5),
  slow(0.3),
  verySlow(0.2);

  const SpeechSpeed(this.rate);

  /// The rate passed to the device voice; 0.5 is its natural speed.
  final double rate;
}
```

`slow` is the default: the learner reported 0.4 as too fast, so the default moves below it. The rates are a starting point to be confirmed by ear on the phone (task 5.2) and are changed in this one place if a step is wrong.

`SpeechSpeed` is a domain model. The numeric rate lives on it because it is the meaning of the choice; a different audio source would map the three names itself.

### 2. The speech repository reads the setting

`TtsSpeechRepository` takes the `SettingsRepository` and reads the speed each time it speaks, then passes the rate to `TtsService.speakJapanese(text, rate: ...)`. The service sets the rate on the engine only when it differs from the last one it set.

So `SpeechRepository.speak(text)` keeps its signature, no ViewModel that plays a sound changes, and a new speed applies to the very next sound. The read is one indexed row from a local database.

Alternatives considered: passing the speed into `speak` from every ViewModel (three ViewModels would each read a setting they do not otherwise care about); pushing the speed into the repository from the settings ViewModel (the repository would hold state that can drift from the stored value).

### 3. Storage

`SettingsRepository` gains `getSpeechSpeed()` and `setSpeechSpeed(SpeechSpeed)`, stored by name under the key `speech_speed`. A missing or unrecognised value reads as `slow`.

### 4. Not part of a backup

`BackupSettings` is not extended. `DriftBackupRepository` neither reads nor writes the key, so an export omits it and an import leaves the phone's value alone, like the date of the last export. The backup format and its version are unchanged.

### 5. Settings screen

In the Sound section, under the voice status: a "Speaking speed" heading, three options in the same pattern as Appearance, and a "Play a sample" button. The sample speaks `あ、か、さ` through `SpeechRepository`, so it uses exactly the path lessons use. When no Japanese voice is available the options stay usable and the sample button is disabled.

`SettingsUiState` gains `speechSpeed`; `SettingsViewModel` gains `setSpeechSpeed` and `playSample`. Choosing a speed plays the sample at once, so one tap answers "how does this one sound?".

### 6. Testing

- **Model and storage**: the default, round trip, an unknown stored value, with the in-memory database.
- **Backup**: a snapshot does not carry the speed, and a restore leaves it unchanged.
- **Repository**: `TtsSpeechRepository` passes the stored speed's rate to the service, and a changed setting is used by the next call. The repository is tested against a small fake service.
- **ViewModel**: loads the stored speed; `setSpeechSpeed` stores it and plays the sample; `playSample` speaks through the speech repository; nothing is spoken when no voice is available.
- **Widget**: the three options and the sample button appear, and the screen fits a small screen with large text in each theme.

## Risks / Trade-offs

- **The slowest speed may sound distorted on some voices** → Judged by ear on the phone; the rate is one constant to adjust.
- **Speed may not be the real problem**: a single kana is brief at any rate → Out of scope here; saying the kana twice is the follow-up if slow speech does not help.
- **Speech slows down for everyone on update** → Intended, and one tap restores Normal.
- **Reading a setting before every sound** → One local row; negligible next to speech itself.

## Migration Plan

No migration. Without a stored value the app uses Slow. Rollback is reverting the change; the extra settings key is ignored by older code.
