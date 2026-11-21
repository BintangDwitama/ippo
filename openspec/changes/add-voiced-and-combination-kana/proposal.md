## Why

The app teaches only the 46 basic kana of each script. Real Japanese words need the voiced kana (が, ざ, だ, ば), the half-voiced kana (ぱ) and the combination kana (きゃ, しゅ, ちょ), so a learner who finishes the basic set still cannot read ordinary text. The learner is about a week from finishing basic hiragana, which is when these are needed.

Adding them as data alone would break the app: an existing hiragana goal would grow from 46 to 104 kana, two kana with duplicate readings (ぢ, づ) would be silently dropped, new hiragana could not be placed before katakana in the teaching order, and two-character kana would not fit the lesson card.

## What Changes

- Add 116 kana: for each script, 20 voiced, 5 half-voiced and 33 combination kana. The app then holds 208 kana.
- Give every kana a **group** (basic, voiced, combination) and a **row** (for example the か row, or the きゃ row).
- Teach voiced and combination kana as rules: their default mnemonic states the rule ("か with two marks: k becomes g") instead of a picture.
- Seeding now **updates app-owned content** (reading, teaching order, group, row, default mnemonic) of kana already in the database. Learner data is never changed by seeding.
- A kana's key may be stated in the seed, so ぢ and づ can coexist with じ and ず.
- **Goals** gain target sets for the new groups. Existing goals keep their meaning: "hiragana" is the 46 basic hiragana. When a goal is achieved, the next step on the path is suggested.
- The teaching path is: hiragana basic, hiragana voiced, hiragana combination, then the same three for katakana.
- **Lessons** introduce whole rows, up to six kana, instead of the next five kana. **BREAKING** for lesson contents after the な row: や ゆ よ is no longer merged with ら り.
- **Wrong options** in multiple-choice questions prefer kana that are easy to confuse with the answer: its voiced or unvoiced partner, kana from the same row, and kana that look alike. Only kana the learner has met are used.
- The kana grid shows each script in three sections. Large kana scale down so two-character kana fit.
- The backup format becomes version 2. Version 1 files still import. A version 2 file is refused by an older app as needing a newer version.
- Not included: katakana for foreign sounds (ファ, ティ, ヴ), particle readings of は, へ and を, a practice mode, and picture mnemonics for the new kana.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `kana-content`: the seeded set grows to 208 kana with groups and rows; seeding updates app-owned content; the grid is sectioned; rule-style mnemonics; two-character kana are displayed whole.
- `kana-lessons`: lessons are whole rows of up to six kana, along the new teaching path.
- `learning-goals`: goal target sets cover the new groups, and the next goal is suggested when one is achieved.
- `review-sessions`: wrong options prefer confusable kana.
- `data-backup`: backups written by earlier versions remain importable.

## Impact

- **Code**: `KanaPayload` and its mapper, the seed parser and loader, `ItemRepository` (content update), `GoalTargetSet`, `GetNextLesson`, `GetGoalProgress`, `BuildChoiceOptions`, `BackupCodec`, `GoalViewModel` and the goal screen, the kana grid ViewModel and screen, and `KanaText`.
- **Assets**: `assets/seed/kana.json` grows from 92 to 208 entries and every entry gains fields.
- **Data**: no schema change. The `payload` JSON of existing items is rewritten by seeding, and the teaching order of existing katakana changes. Learner data (introduced dates, cards, reviews, goals, own mnemonics) is untouched.
- **Existing learners**: an active goal keeps its size and pace. Wrong options become harder at once, so measured accuracy may dip for a while.
- **Backups**: files exported after this change cannot be imported by the previous version of the app.
- **Tests**: seed integrity, seeding over a database in the previous state, lesson rows, option selection, goal target sets, backup versions, and layout with two-character kana.
- **Manual verification**: an in-place update on the phone with real progress, checking that the goal, cards and streak are unchanged.
