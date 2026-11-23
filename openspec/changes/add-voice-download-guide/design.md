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

Whether the intent should be aimed at the default engine's package or left open is checked against the documentation in the first task. Left open, a phone with two engines shows a chooser; aimed, it goes straight to the engine actually in use.

Alternative: open the system's text-to-speech settings page. Rejected as the first choice because it leaves the learner two or three taps from the download, on a page that differs per phone maker; it is the fallback the instructions describe.

### 4. Preferring a downloaded voice

When Japanese is first set up, `TtsService` reads the voice list and, if any `ja-JP` voice has `network_required` false and is not marked not-installed, selects it with `setVoice`. Otherwise it only sets the language, as today, and the engine decides.

Among several downloaded voices the first in the engine's order is taken. The owner's phone sounded right with the engine's default; the task list checks that selecting a voice explicitly does not change which voice the owner hears, and if it does, the selection applies only when the engine's default is an online voice.

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
