## Why

On a second phone the app's sound was noticeably late. The app has no audio of its own: it asks the phone's text-to-speech engine to speak, and the engine needs a Japanese voice. A phone can have that voice in three states, and the app only recognises two of them. When the voice exists but has not been downloaded, the engine may fetch each sound over the network: sound is late, fails without internet, and the app says nothing, because it only warns when there is no Japanese voice at all. Whoever installs a shared copy of the app has no way to know what is wrong.

The cause on that phone is a strong suspicion, not yet confirmed (see the first task).

## What Changes

- **Recognise three states of the Japanese voice**: ready (downloaded, works offline), online only (works, but each sound may come from the network), and missing.
- **Explain the online-only state**: the home screen notice and the settings row say that sound may be late or absent without internet, and that downloading the voice fixes it. Today both stay silent in that state.
- **One tap to the download**: a button on the notice and in settings opens the speech engine's own "install voice data" screen, instead of describing a path through the phone's settings. If the phone cannot open that screen, the written instructions remain.
- **Notice when the voice arrives**: the state is checked again whenever the home or settings screen is shown, so the notice disappears after the download without restarting the app. Today the answer is remembered for as long as the app runs.
- **Use the downloaded voice when there is one**: when the phone has both an online and a downloaded Japanese voice, the app asks for the downloaded one.
- **Wake the speech engine at start**, so the first sound of a session is not the slow one.

Not in this change: shipping recorded audio inside the app; downloading a voice without the learner's tap (Android does not allow one app to install another app's data).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `speech-audio`: the fallback requirement gains the online-only state and the direct route to the download; new requirements for preferring a downloaded voice, rechecking the voice, and readiness of the first sound.

## Impact

- **Data layer**: `SpeechRepository` reports a voice status instead of a yes/no (the yes/no stays, derived from it) and can open the download screen; `TtsService` uses more of the `flutter_tts` plugin (installed-language check, voice list, voice selection).
- **Android**: `MainActivity` gains one more channel method, opening the engine's voice-data screen. The plugin does not offer this.
- **UI**: home notice and settings row show three states and the button; both recheck when shown.
- **Settings**: the "notice shown" flag is kept as it is; a dismissed notice stays dismissed, and settings always shows the state.
- **Tests**: the fake speech repository gains the new state.
- No new package. No data or backup changes. The app remains offline; opening a system screen is not network access.
- **Depends on the engine**: which voices exist and whether the download screen opens is up to each phone's speech engine. Behaviour is verified on the owner's phone and, if possible, the second phone.
