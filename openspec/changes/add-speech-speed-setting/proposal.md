## Why

The app speaks every kana at one fixed speed, and the learner finds it too fast to hear clearly. Device voices differ from phone to phone, so no single value suits everyone; the learner needs to choose the speed by ear.

## What Changes

- Add a **Speaking speed** setting with three choices: Normal, Slow and Very slow. Slow is the default and is slower than today's fixed speed.
- Add a **Play a sample** action next to it, so the learner can hear the chosen speed without leaving settings.
- Apply the chosen speed to every spoken kana: in lessons, reviews and the kana detail screen.
- Keep the choice on the phone. It is not written to backup files and is not changed by importing one, because the right speed depends on the phone's voice.
- Not included: saying a kana twice, a slow-replay button, a free slider, or changing the voice's pitch.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `speech-audio`: adds a requirement that the speaking speed can be chosen and is applied to all speech.

## Impact

- **Code**: a `SpeechSpeed` domain model; `SettingsRepository` and its drift implementation and fake (one new setting); `TtsService` and `TtsSpeechRepository` (apply the speed); `SettingsViewModel`, `SettingsUiState` and the settings screen.
- **Data**: one new key in the existing `settings` table. No schema change.
- **Behaviour for existing learners**: speech becomes slower after the update, because the default is slower than the old fixed value.
- **Backup**: unchanged format. The new setting is deliberately left out.
- **Manual verification**: the three speeds have to be judged by ear on the phone.
