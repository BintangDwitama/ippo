## Why

The learner is starting Japanese from zero and cannot use any other part of the planned app (vocabulary, kanji, the AI partner, capture from real content) until they can read kana. A kana trainer is the smallest slice that is useful on its own, and it forces us to build the general review scheduler and card model that every later stage reuses.

## What Changes

- Create the Flutter application (Android first) with the layered architecture defined in the project standards.
- Ship seeded content for the 46 basic hiragana and 46 basic katakana: character, romaji reading, and an original mnemonic for each.
- Add a lesson flow that introduces a small batch of new kana at a time, mnemonic first, with audio.
- Add a spaced-repetition scheduler (FSRS) over a generic card model, so vocabulary and kanji cards can reuse it later.
- Add interleaved review sessions that mix hiragana and katakana and mix prompt types: character to sound, sound to character, multiple choice, and typed romaji.
- New kana start as multiple-choice cards and graduate to typed-answer cards after repeated success.
- Let the learner replace any seeded mnemonic with their own.
- Add one SMART goal with a preset ("all 46 hiragana at 90% accuracy within 14 days"), turned into a daily quota of new kana, a daily review cap, a streak, and a daily reminder notification.
- Add a kana grid showing the learning status of every character.
- Play audio for every kana using the device's Japanese text-to-speech voice.
- Store everything locally in SQLite. No server, no account, no AI in this change.

## Capabilities

### New Capabilities

- `kana-content`: The seeded kana set (characters, readings, mnemonics), learner-edited mnemonics, and the kana grid showing status per character.
- `kana-lessons`: Introducing new kana in small batches, mnemonic first, and creating their review cards.
- `review-scheduling`: The generic card model and the spaced-repetition scheduler that decides when each card is next due.
- `review-sessions`: Interleaved review sessions, prompt types, answer checking, and graduation from multiple choice to typed answers.
- `learning-goals`: The SMART goal, daily quota of new kana, daily review cap, streak, progress, and reminder notification.
- `speech-audio`: Playing the spoken sound of a kana, with a clear fallback when no Japanese voice is available.

### Modified Capabilities

None. This is the first change in the project.

## Impact

- **Code**: a new Flutter project at the repository root. No existing code is affected.
- **Dependencies** (new): `provider`, `go_router`, `drift` with SQLite, an FSRS implementation for Dart, `flutter_tts`, `flutter_local_notifications`.
- **Platform**: Android only is built and tested. iOS folders are generated but not built.
- **Permissions**: Android notification permission for the daily reminder.
- **Data**: a local database on the device. Uninstalling the app loses progress; backup and export are out of scope for this change.
- **Out of scope**: voiced and combination kana (dakuten, handakuten, yōon), vocabulary, kanji, the AI partner, speech recognition, handwriting, sync, and iOS builds.
