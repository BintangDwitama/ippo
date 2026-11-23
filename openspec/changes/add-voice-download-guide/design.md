## Context

Sound comes from the phone's text-to-speech engine through the `flutter_tts` plugin (4.2.5). `TtsService` wraps it; `TtsSpeechRepository` implements `SpeechRepository` (`isJapaneseVoiceAvailable`, `speak`, `stop`). The repository asks the engine once whether Japanese is available and remembers the answer for the life of the app.

"Available" in the plugin means the engine supports the language. A voice that must be fetched over the network counts. So a phone whose Japanese voice is not downloaded passes the check, gets sound that may be late or fail offline, and sees no notice. That is the suspected cause of delayed sound on a second phone the owner tried; it is not confirmed.

What the plugin offers on Android (read from its source): `isLanguageInstalled(language)`, true when a voice for the language exists that does not need the network and is not marked "not installed"; `getVoices`, each with `name`, `locale`, `network_required` and `features`; `setVoice`. It does not offer a way to open the engine's voice-data screen.

`MainActivity` already has a method channel, added for the launch screen.

## Goals / Non-Goals

**Goals:**

- A learner whose sound is late or missing is told why and is one tap from the fix.
- The app notices the fix without a restart.
- The app does not choose an online voice when a downloaded one exists.

**Non-Goals:**

- Audio shipped in the app.
- Downloading a voice without the learner's confirmation; Android does not allow it.
- Choosing between several downloaded voices, or a voice picker.
- Other platforms. The checks degrade to today's behaviour where the plugin cannot answer.

## Decisions

### 1. Three states, one enum

`JapaneseVoice { ready, onlineOnly, missing }` in the domain models.

- `missing`: the engine does not support Japanese (`isLanguageAvailable` false).
- `ready`: `isLanguageInstalled('ja-JP')` true.
- `onlineOnly`: supported but not installed.

`SpeechRepository.getJapaneseVoice()` returns it. `isJapaneseVoiceAvailable()` stays and means "not missing", so review sessions, lessons and the existing callers are untouched: an online-only voice still speaks.

If the plugin throws or cannot answer the installed question, the state falls back to `ready` when the language is available. Reporting a problem that may not exist is worse than staying quiet.

### 2. Rechecking

The repository no longer remembers the answer forever. `getJapaneseVoice()` asks the engine each time; the home ViewModel's `refresh()` and the settings ViewModel's `reload()` already run when their screens are shown or returned to, and call it. The check is two plugin calls and not on any hot path: `speak` uses a remembered state that those refreshes update, so speaking does not query the engine twice per sound.

### 3. Opening the download screen

Android defines `TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA`: an activity of the speech engine that lets the user download voice data. `MainActivity` gains a second channel (`ippo/speech_setup`, method `openVoiceDownload`) that starts it and answers whether it could be started (no activity to handle it, or a security exception, answers false).

`SpeechRepository.openVoiceDownload()` returns that boolean; false also where there is no Android side. The UI shows the written instructions when it is false.

The documentation gives no guidance on aiming the intent at one engine. The implementation tries the engine in use first (the system's `tts_default_synth` setting) and, if that cannot be started, the open intent; false only when both fail. Aimed, a phone with two engines goes straight to the one actually speaking.

Alternative: open the system's text-to-speech settings page. Rejected as the first choice because it leaves the learner two or three taps from the download, on a page that differs per phone maker; it is the fallback the instructions describe.

### 4. Preferring a downloaded voice

The rule, after seeing what a real engine reports (see Findings): when Japanese is set up, the app reads the voice list. If the voice the engine uses for the language by default (marked `legacySetLanguageVoice`) works offline, the app only sets the language and leaves the choice to the engine, so a phone that already sounds right keeps its voice. Only when that default would need the network, or its data is not downloaded, and another Japanese voice works offline, does the app ask for that one by name (the first by name, so the choice does not depend on the engine's order). With no offline voice, the engine decides, as before.

The first design selected any downloaded voice. On the owner's phone that would have swapped the default voice for a differently named one and possibly changed how the app sounds, for no gain.

Selection is redone when a recheck finds the state changed, so a voice downloaded mid-session is used from the next sound.

### 5. Waking the engine

`main.dart` calls a new `SpeechRepository.prepare()` after `runApp`, unawaited and with errors swallowed, as the reminder reconciliation is. It binds the engine, sets the language and voice, and reads the state. It must not delay the first frame; the earlier launch measurements showed startup is already sensitive.

What this does not do: remove the engine's own time to synthesise a sound. If the delay on the other phone is that, only a downloaded voice or shipped audio helps.

### 6. What the learner sees

Home notice (shown once, as today; one "notice shown" flag for both states, so dismissing it for one state does not bring it back for the other):

- Missing: "No Japanese voice found" with today's explanation, plus the button.
- Online only: "Japanese voice not downloaded. Sound may be late, or missing without internet. Download the voice to fix this." plus the button.

Settings, "Japanese voice" row, always: ready ("Downloaded. Kana and words are read aloud."), online only (the explanation and the button), missing (the explanation and the button).

Button: "Download voice". On failure to open, a short message with the path: Settings > Accessibility > Text-to-speech > the engine's settings > Install voice data > Japanese.

`HomeUiState.showVoiceNotice` becomes a nullable `JapaneseVoice` to show; `SettingsUiState.isJapaneseVoiceAvailable` becomes the enum.

### 7. Testing

- **Repository**, with a fake `TtsService`: the three states; fallback to ready when the installed check fails; recheck sees a change; `speak` skipped only when missing; a downloaded voice is selected when present and not otherwise; `prepare` never throws.
- **ViewModels**: home and settings show each state, recheck on refresh, and report whether the download screen opened.
- **Widgets**: notice and settings row in each state, in three themes on a small screen with large text; the button; the fallback message.
- **On a phone**: the owner's phone should report ready and sound as before. The online-only path needs a phone in that state: the second phone, or the owner's with the Japanese voice data removed and restored (the owner's choice; not done without asking).

## Findings

**The second phone (task 1.1)**: not checked. The owner started the work without reporting the airplane-mode test, so the cause of the delay there remains a suspicion.

**Documentation (task 1.2)**, read 2026-11-23:

- `ACTION_INSTALL_TTS_DATA` "Triggers the platform TextToSpeech engine to start the activity that installs the resource files on the device that are required for TTS to be operational." The app "shouldn't expect successful installation upon return from that intent", which is why the state is rechecked instead of assumed.
- The "not installed" feature means "the voice may need to download additional data to be fully functional. The download will be triggered by calling setVoice(Voice) or setLanguage(Locale). Until download is complete, each synthesis request will either report ERROR_NOT_INSTALLED_YET error, or use a different voice to synthesize the request." So merely using the app may start the download, and until it finishes sound can come from another, possibly online, voice. This matches late sound on a phone that has never spoken Japanese, and it means the delay may cure itself once the download completes.
- A network voice's expected latency is documented as about 200 ms or more, against 20 to 50 ms for a local one.
- The manifest already declares the text-to-speech service in `queries`, as required from Android 11.

**The owner's phone (task 1.3)**, Samsung SM-S731B, Android 16, read with a temporary build that was removed afterwards: the engine is Google's (`com.google.android.tts`); Japanese is available and installed; of 474 voices, 9 are Japanese: `ja-JP-language` (offline, the language default), four `-local` voices (offline) and four `-network` voices. So this phone is in the ready state, the engine's default is already offline, and the app asks for no voice by name.

## Checks on phones

2026-11-23. Asked to check the path for a voice that is not downloaded (the notice, the Download voice button, the notice clearing after the download), the owner reported: "the download doing well". Which phone this was on, and each step separately, were not reported.

## Known gap, deferred by the owner

Reported by the owner on 2026-11-23: on some phones from Chinese makers the speech engine does not offer Japanese at all. That is the missing state, and this change does not help there: the download button opens the maker's own screen, which has no Japanese to download. The phone was not examined; its maker, model and whether it has the Play Store are not known.

Options discussed and deferred as an edge case: using another engine already installed on the phone that does speak Japanese; telling the learner to install Google's speech engine; shipping audio inside the app, the only option that works on a phone without the Play Store, which still needs a source of audio that may be redistributed (generating it with an open-source speech program was raised and not researched).

## Risks / Trade-offs

- **The diagnosis is wrong** and the other phone's delay has another cause → Task 1.1 asks the owner for the airplane-mode check before building. The change is still worthwhile without it (the silent online-only state is real), but the proposal's motivation is then weaker and that is said plainly.
- **An engine reports voices misleadingly** (marks a downloaded voice as needing the network, or the reverse) → The notice can be dismissed, and never blocks anything. Settings shows the state without nagging.
- **The download screen does not open on some phones** → Written instructions as fallback.
- **Selecting a voice changes how the owner's phone sounds** → Checked by ear; selection is narrowed if so.
- **A recheck on every home refresh costs time** → Two plugin calls; measured on the phone if the home screen feels slower.
- **The second phone is not available for testing** → The online-only path is then verified only by tests with fakes, and that limit is recorded.

## Open Questions

- Whether the delay on the second phone was an online voice. Answered by the airplane-mode check.
- Whether to aim the download intent at the default engine's package. Answered from the documentation in task 1.2.
