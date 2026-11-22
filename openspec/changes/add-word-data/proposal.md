## Why

The app teaches kana and nothing a learner can do with them. The next stage is reading real words, unlocked as soon as every kana in a word has been learned. Before any screen is built, the words themselves have to exist: chosen for a beginner, ordered, checked, and properly attributed. Doing the data first lets the list be read and corrected before anything depends on it.

## What Changes

- Add a **script** in the repository that builds the app's word list from two open sources: the JMdict dictionary (content) and a beginner vocabulary list at the first two exam levels (selection and order).
- Add the generated **word file**, holding roughly 1,200 to 1,500 words. Each word has a stable id, its reading in kana, its usual written form, one or two short English meanings, a part of speech, a level, a position in the learning order, and the list of kana a learner must know to read it.
- Apply fixed **selection rules**: only words readable with the 211 kana the app teaches; nothing the dictionary marks as archaic, obscure or vulgar; one word per reading, keeping the most basic.
- Add an **override file** for correcting a meaning or written form, or leaving a word out, without editing generated data.
- Add a generated **preview** showing which words become readable after each row of kana, for the owner to review.
- Add **attribution and licence** notices for both sources, and state the date of the dictionary data. The word file is published under the dictionary's licence.
- Add a **monthly job** that rebuilds the word file from the latest dictionary and proposes the result as a pull request.
- The word file is **not shipped in the app** by this change. Nothing a learner sees changes.

Decided and left for later changes:
- Word lessons, word cards, the About screen with the required acknowledgement, and bundling the file in the app (the next change).
- The app downloading newer word data, which gives it internet permission (after the word screens).
- Automatic backup to the learner's own cloud storage (parked until a server is decided).
- A backend of our own (not before the AI partner).

## Capabilities

### New Capabilities

- `word-data`: which words the app's list contains, what is recorded for each, how the list is built and kept current, and how its sources are credited.

### Modified Capabilities

None.

## Impact

- **Code**: a new `tool/words/` script with its logic and tests. No change under `lib/`.
- **Data**: new files under `data/words/`: the word file, the override file, the vendored beginner list, the preview, and licence and source notices.
- **Repository**: its first automation, a scheduled workflow under `.github/workflows/`. Opening pull requests from a workflow needs a repository setting the owner has to switch on.
- **Licences**: the word file is under Creative Commons Attribution-ShareAlike 4.0, as the dictionary requires for derived files. The app's code is not affected. The beginner list is credited to its author under Creative Commons Attribution; its original licence statement could not be read first-hand because the author's site is gone, and this rests on consistent statements by projects that republished it.
- **App**: none. No new permission, no new asset, no behaviour change.
- **Owner's part**: reading the preview and saying which words or meanings look wrong.
