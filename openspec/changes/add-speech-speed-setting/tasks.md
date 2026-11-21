## 1. Model and storage

- [x] 1.1 Add the `SpeechSpeed` domain model (normal, slow, verySlow) with its rate and a `fromName` that falls back to slow
- [x] 1.2 Add `getSpeechSpeed` and `setSpeechSpeed` to `SettingsRepository`, the drift implementation (key `speech_speed`) and the fake
- [x] 1.3 Tests: default is slow, round trip, an unknown stored value reads as slow
- [x] 1.4 Tests: a backup snapshot does not carry the speed and a restore leaves it unchanged

## 2. Applying the speed

- [x] 2.1 Let `TtsService.speakJapanese` take a rate and set it on the engine only when it changes
- [x] 2.2 Give `TtsSpeechRepository` the `SettingsRepository`, read the speed on each `speak`, and pass its rate to the service; update the wiring in `main.dart`
- [x] 2.3 Tests against a fake service: the stored speed's rate is used, and a changed setting is used by the next call

## 3. Settings screen

- [x] 3.1 Add `speechSpeed` to `SettingsUiState`, and `setSpeechSpeed` and `playSample` to `SettingsViewModel`; choosing a speed plays the sample
- [x] 3.2 ViewModel tests: loads the stored speed, stores a new one and plays the sample, plays nothing when no voice is available
- [x] 3.3 Add the "Speaking speed" options and the "Play a sample" button to the Sound section, disabled when no Japanese voice is available
- [x] 3.4 Widget tests: the options and the button appear and work; the settings screen fits 360 by 640 logical pixels at text scale 1.3 in each theme

## 4. Checks

- [x] 4.1 Run `flutter analyze` and `flutter test`; fix all issues
- [x] 4.2 Update README.md to mention the speaking speed setting

## 5. On the phone

- [ ] 5.1 Build a release APK, install it over the app, and confirm progress is intact
- [ ] 5.2 The owner listens to the sample at each of the three speeds and in a review, and says whether each step is right; adjust the rates if not
