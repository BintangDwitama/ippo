## Why

The app teaches kana but gives the learner nothing to read with them. A list of 1,291 beginner words now exists in the repository (`data/words/`), each recorded with the kana needed to read it. Teaching those words as soon as they become readable gives every row of kana an immediate use, turns reviews into reading practice, and starts the vocabulary the later stages need.

## What Changes

- **Bundle the word list** in the app and load it into the database as a second kind of item beside kana, kept in line with the bundled file on every launch as kana are.
- **Unlock words by kana**: a word becomes available when every kana in its reading has been introduced. After the first row that is 14 words; after three rows, 85.
- **Word lessons**: up to five new words a day, in the list's learning order. Each word is shown with its reading, its written form in small type, its meanings and its sound, followed by a short check.
- **Two review cards per word**, in the normal review session mixed with kana cards: see the word and choose its meaning; see the meaning and choose the word. Wrong options are words of the same type that do not share a reading or a meaning with the answer.
- **The written form is shown on every word card**, small, under the reading. It is what tells apart words that share a reading (雨 and 飴 are both あめ).
- **Words are spoken** from their reading, on request in a lesson and after each answer in a review.
- **Home screen**: a word lesson is offered with a preview of its words, after reviews and kana lessons.
- **About and sources screen**, reached from settings: credit to JMdict and the EDRDG with the dictionary date, credit to the JLPT list's authors, and the licences of bundled software and fonts. The dictionary's licence requires this once the app uses the data.
- **Backups** include word progress. The backup format version rises to 3 so that an older app refuses a newer file cleanly. A backup that names a word this app's list no longer has is imported without that word, and the summary says so.

Not in this change: a screen to browse all words, listening-only cards, typed answers for words, goals or a pace setting for words, downloading newer word data.

## Capabilities

### New Capabilities

- `word-content`: the bundled word list as learnable items, and how it is kept in line with the list shipped in the app.
- `word-lessons`: when a word becomes available, the daily pace, what a word lesson shows and checks, and what completing one creates.
- `sources-credit`: the About and sources screen and what it must state.

### Modified Capabilities

- `review-sessions`: adds the two word prompt types and their wrong options; feedback for word cards; interleaving covers words.
- `home-screen`: the primary action order gains word lessons; a word lesson preview is added.
- `speech-audio`: speaking a word.
- `data-backup`: backups hold word progress; words unknown to the importing app are skipped instead of refusing the file; counts in the summary cover words.

## Impact

- **Data**: `pubspec.yaml` bundles `data/words/words.json` (about 240 KB). No database schema change: items already carry a kind and a JSON payload; prompt types are stored by name.
- **Domain**: `ItemKind.word`, `WordPayload`, two `PromptType` values; new use cases for the next word lesson and for word choice options; `CompleteLesson`, `GradeAnswer` and every reader of `item.kana` must tell the two kinds apart.
- **Data layer**: a word seed loader; `ItemPayloadMapper`; `syncSeedItems` must handle 1,291 items quickly; backup codec version 3 and import of unknown words.
- **UI**: new word lesson screen and About screen; review screen renders word cards; home screen shows the word lesson; settings links to About.
- **Launch time**: syncing the word list on every start is new work on the startup path and must be measured on the phone.
- **Review load**: two more cards per word, up to ten new cards a day at the default pace, within the existing daily review cap.
- **Docs**: `data/words/README.md` and the main README say the list is not used by the app; that becomes untrue.
- No new dependencies. No network access.
