## 1. Confirm before building

- [ ] 1.1 The owner checks the second phone: is every sound late or only the first; does sound stop in airplane mode; which phone and speech engine. Record the answer in design.md, or record that it could not be checked
- [ ] 1.2 Read the Android documentation for `ACTION_INSTALL_TTS_DATA`, `Voice.isNetworkConnectionRequired` and the "not installed" voice feature; decide whether to aim the intent at the default engine; record in design.md
- [ ] 1.3 On the owner's phone, list the Japanese voices the engine reports (name, network required, features) and what `isLanguageInstalled` answers; record in design.md

## 2. Voice state

- [ ] 2.1 Add the `JapaneseVoice` model and `SpeechRepository.getJapaneseVoice()`; derive `isJapaneseVoiceAvailable()` from it; stop remembering the answer forever
- [ ] 2.2 Extend `TtsService` with the installed check and the voice list, behind methods a fake can replace
- [ ] 2.3 Select a downloaded Japanese voice when one exists; reselect when the state changes
- [ ] 2.4 Add `SpeechRepository.prepare()` and call it after `runApp`, unawaited, errors swallowed
- [ ] 2.5 Tests for 2.1 to 2.4 with a fake service, including failures of each plugin call

## 3. Opening the download screen

- [ ] 3.1 Add the channel method in `MainActivity` that opens the engine's voice-data screen and reports whether it opened
- [ ] 3.2 Add `SpeechRepository.openVoiceDownload()` with the method-channel call, false where there is no Android side
- [ ] 3.3 Tests: opened, not opened, no Android side

## 4. Screens

- [ ] 4.1 Home: show the notice for the missing and online-only states with the Download voice button; recheck on refresh; show the written path when the screen cannot be opened
- [ ] 4.2 Settings: the Japanese voice row shows the three states with the button when not ready; recheck on reload
- [ ] 4.3 Update the fake speech repository and the existing tests that use a yes/no voice
- [ ] 4.4 Tests: ViewModels in each state and on recheck; widgets in each state in three themes on a small screen with large text

## 5. Checks

- [ ] 5.1 Run `flutter analyze` and `flutter test`; build and install the release
- [ ] 5.2 The owner checks their phone: sound is as before, the first sound of a session is prompt, settings shows the voice as downloaded, no notice appears
- [ ] 5.3 Check the online-only path on a phone in that state (the second phone, or the owner's with the voice data removed if the owner agrees): notice, button, download, notice gone on return. If no such phone is available, record that this path is verified by tests only
- [ ] 5.4 Record what the checks found in design.md, fix what they turn up, and update the README
