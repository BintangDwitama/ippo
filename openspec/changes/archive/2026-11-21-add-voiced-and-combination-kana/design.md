## Context

`assets/seed/kana.json` has 92 entries with `script`, `character`, `romaji`, `alt`, `order` and `mnemonic`. `KanaSeedLoader` builds each item's key as `script:romaji` and `DriftItemRepository.insertSeedItems` inserts only keys that are missing; it never changes an existing row. Hiragana have orders 0 to 45 and katakana 100 to 145.

Code that assumes "a script is one set of 46":
- `GoalTargetSet.includes(KanaScript)` decides which kana a goal covers; `GetNextLesson` and `GetGoalProgress` both use it.
- `GetNextLesson` takes the next five candidates by `sortOrder`.
- `BuildChoiceOptions` draws wrong options at random from introduced kana of the same script.
- `KanaGridViewModel` lays one script out as a single table.
- `KanaText` draws the character at a fixed size.

The learner has real progress on the phone (an active basic-hiragana goal). Decisions from exploration: all of hiragana before katakana; lessons are whole rows of up to six; confusable wrong options are part of this change.

## Goals / Non-Goals

**Goals:**
- All 208 kana are teachable, in an order that completes one script before the next.
- Updating the app changes nothing about an existing learner's goal, cards, history or pace.
- The seed file is the single source of app-owned content, and a later edit to it reaches existing installs.
- Multiple-choice questions test real discrimination.

**Non-Goals:**
- Katakana for foreign sounds (ファ, ティ, ヴ and similar); they belong with loanwords in stage 1.
- The ぢゃ row, which is not in standard charts.
- Particle readings of は, へ and を.
- Picture mnemonics for the new kana.
- A schema change.

## Decisions

### 1. Seed entry format

```json
{"script": "hiragana", "character": "が", "romaji": "ga", "alt": [],
 "group": "voiced", "row": "g", "family": "ka", "lookalikes": [],
 "order": 100, "mnemonic": "か (ka) with two small marks: the k sound becomes g."}

{"script": "hiragana", "character": "ぢ", "romaji": "ji", "alt": ["di", "zi"],
 "key": "hiragana:di", "group": "voiced", "row": "d", "family": "chi", ...}
```

- `group`: `basic`, `voiced` (includes half-voiced) or `combination`.
- `row`: the consonant line the kana belongs to. Lessons and the grid use it.
- `family`: the reading of the unvoiced basic form. か and が share `ka`; は, ば and ぱ share `ha`; きゃ and ぎゃ share `kya`. Kana with the same family are partners.
- `lookalikes`: characters of the same script that are easily mistaken for this one. Hand-written, mostly for basic kana (あ/お, さ/き, ぬ/め, ね/れ/わ, は/ほ, る/ろ, シ/ツ, ソ/ン, ク/タ/ケ).
- `key`: optional. Defaults to `script:romaji`, so all 92 existing keys are unchanged. Stated only for ぢ (`di`), づ (`du`) and their katakana.

All four new fields are stored in the item's `payload` JSON through `KanaPayload` and `ItemPayloadMapper`. A payload without them (a database not yet re-seeded) decodes as `basic`, an empty row, its own reading as family and no lookalikes, so the app never fails on old rows.

### 2. Teaching order

`order` is rewritten so the whole path is one ascending sequence:

| Range | Kana |
|---|---|
| 0 to 45 | hiragana basic (unchanged) |
| 100 to 124 | hiragana voiced |
| 200 to 232 | hiragana combination |
| 1000 to 1045 | katakana basic (was 100 to 145) |
| 1100 to 1124 | katakana voiced |
| 1200 to 1232 | katakana combination |

Gaps leave room for later additions without renumbering. Alternative considered: ordering by (script, group, order) in code. Rejected: the path would live in two places, the seed and the comparator.

### 3. Seeding updates app-owned content

`ItemRepository.insertSeedItems` becomes `syncSeedItems`. In one transaction, for each seed entry:
- no item with that key: insert the item and its mnemonic row, as today;
- item exists: update `payload` and `sort_order` on the item and `default_text` on its mnemonic, only when they differ.

It never writes `introduced_at`, `learner_text`, or any other table, and never deletes an item. It still runs on every launch; when nothing differs it writes nothing, so streams do not emit needlessly.

A kana removed from a later seed file stays in the database. Removing content that may have cards is a separate decision.

### 4. Goal target sets

```dart
enum GoalTargetSet {
  hiragana,          // 46 basic hiragana (unchanged meaning)
  katakana,          // 46 basic katakana (unchanged meaning)
  both,              // 92 basic kana (unchanged meaning)
  hiraganaExtended,  // 58 voiced and combination hiragana
  katakanaExtended,  // 58 voiced and combination katakana
  everything;        // all 208

  bool includes(KanaPayload kana);
}
```

`includes` takes the kana, not the script, and `GetNextLesson` and `GetGoalProgress` call it that way. Values are stored by name, so existing rows and version 1 backups keep working and no migration is needed.

Alternative considered: a goal as script plus a set of groups. More general, but it needs new columns and a migration for one extra level of choice.

When a goal is achieved, the goal screen preselects the next step: hiragana → hiraganaExtended → katakana → katakanaExtended. After `both` it suggests `everything`; after `katakanaExtended` or `everything` it keeps the current choice. This replaces the single hard-coded "hiragana then katakana" suggestion in `GoalViewModel`.

The goal screen's three-segment control becomes a list of six options, each with its count of kana, using the same option pattern as the Appearance setting. The first-launch preset is unchanged.

Without an active goal, lessons follow the path over all kana at the default pace.

### 5. Lessons are whole rows, up to six kana

`GetNextLesson` keeps its quota logic and changes only how the batch is cut from the ordered candidates:

1. Take the remaining kana of the first candidate's row.
2. While the next row has the same script and group, and adding all of its remaining kana keeps the lesson at six or fewer, add it.

| Kana | Lessons |
|---|---|
| Basic | five per row; や ゆ よ alone; わ を with ん |
| Voiced | five per row |
| Combination | two rows of three together; the last row alone |

A lesson never mixes scripts or groups. A row left partly introduced by the old rule (for example る れ ろ) is finished first and then joined by following rows under the same limit. `maxBatchSize` becomes 6.

As before, the quota decides whether a lesson is offered, not its size.

### 6. Wrong options prefer confusable kana

`BuildChoiceOptions` keeps its contract (the correct kana plus three others of the same script with a different reading, shuffled) and ranks the candidates the learner has met, meaning introduced or in the current lesson:

1. partners: same `family`;
2. look-alikes: listed in either kana's `lookalikes`;
3. the same row;
4. any other kana the learner has met.

Within a tier the order is random, so questions vary. If fewer than three have been met, the nearest kana in teaching order fill the gap, as today. Kana with the same reading as the answer (じ and ぢ) are never offered against each other, which the existing reading check already ensures.

The same options serve both multiple-choice prompt types.

### 7. Rule-style mnemonics

The default mnemonic of a voiced or combination kana states its rule and names the base kana:

- voiced: "か (ka) with two small marks: the k sound becomes g."
- half-voiced: "は (ha) with a small circle: the h sound becomes p."
- combination: "き (ki) with a small や (ya), said as one beat: kya."
- ぢ and づ add that they read like じ and ず and are rare.

They are produced from a pattern during implementation and then live in the seed file like any other mnemonic; the learner can replace them. The lesson flow is unchanged: character, reading, mnemonic and sound, then the quiz.

### 8. Screens

- **Kana grid**: for the selected script, three sections with headings (Basic, Voiced, Combination), each laid out by row with the existing vowel columns; combination rows fill the a, u and o columns. The counts line covers the whole script. `KanaGridUiState.rows` becomes a list of sections.
- **Large kana**: `KanaText` scales down to the width it is given, so きゃ at lesson size fits a 360-pixel screen on one line.
- **Kana tiles and answer buttons** already scale their content.

### 9. Backup format version 2

`BackupCodec.formatVersion` becomes 2. The structure is unchanged; version 2 only allows the new target set names and item keys. The codec reads versions 1 and 2. An older app refuses a version 2 file as "needs a newer version of Ippo" instead of "damaged", which is why the number is raised even though the structure is the same. The version 1 fixture stays in the tests and a version 2 fixture is added.

### 10. Testing

- **Seed integrity** (reads the real asset): 208 entries; unique keys; unique script and character pairs; 46, 25 and 33 per script by group; no row longer than five; orders unique and ascending along the path; every `lookalikes` character exists in the same script; every family has a basic member; the 92 original keys are all present.
- **Seeding over the previous state**: a database seeded from a copy of the current seed file (kept as `test/fixtures/kana_seed_v1.json`), with introduced kana, cards, reviews, a goal and a learner mnemonic. After syncing the new seed: learner data is identical, the 92 items have new payload fields and orders, 116 items are added, and a second sync writes nothing.
- **Lessons**: the rows table above, the path across groups and scripts, a partly introduced row, and the quota cases.
- **Options**: each tier, the mix when tiers are short, the first lesson, same-reading exclusion.
- **Goals**: `includes` for each target set, progress totals (46, 58, 92, 208), the next-goal suggestion.
- **Backup**: version 1 and version 2 fixtures decode; version 3 is refused as newer.
- **UI**: the grid sections; a lesson and a review with a combination kana at 360 by 640 with large text in each theme; the goal screen's six options.

### 11. Notes from implementation

- **The seed was produced by a one-off script** from the previous 92 entries plus tables of rows, readings and rule sentences. The script is not in the repository; `assets/seed/kana.json` is the source of truth. All 116 new entries were read through once; none needed correcting.
- **Katakana were already ordered from 100**, not 46 as first written here, so the new hiragana could not use 100 to 232 without the renumbering. The table in decision 2 is corrected.
- **Kana with an unknown row** (a payload not yet re-seeded) fall back to lessons of the next five, the old rule. Seeding runs before the first frame, so this is only a safety net.
- **The family of a combination kana is the unvoiced combination** (ぎゃ belongs to `kya`), so きゃ and ぎゃ are partners. The plain base kana (き) is not a partner of きゃ.
- **Look-alikes count in both directions**, so listing a pair on one side would be enough; the seed lists both and a test requires it.
- **The home screen's lesson preview showed five tiles**, which cut the sixth kana of a paired combination lesson. It now shows as many tiles as the lesson has. A screen test found this.
- **Goal choices are listed along the teaching path**, not in the order the values are stored: hiragana basics, hiragana voiced and combination, katakana basics, katakana voiced and combination, both basic sets, all kana.
- **Run against a copy of the phone's real database** (taken 21 Nov 2026, 10 of 46 hiragana introduced, 20 cards, 30 reviews): learner data was byte-identical in a backup before and after seeding, the goal still read 10 of 46 with the same accuracy and days remaining, the database grew to 208 kana, and the next lesson was さ し す せ そ.
- **Full path check**: a test introduces every lesson in turn with no goal and finds 42 lessons, none above six kana and none mixing scripts or groups.

### 12. Results on the phone (Samsung SM S731B, Android 16), 22 Nov 2026

- **In-place update (task 10.3): passed.** Before the update the home screen showed 10 cards to review, the さ row as the next lesson, 11 days left, 10 of 46 kana introduced, 100% accuracy and a 1-day streak. After installing the release build over the app it showed exactly the same. A version 1 backup was exported from the old build first and copied off the phone.
- **Screens (task 10.4): passed.** The grid opens with a Basic section and the count "0 known, 10 learning, 94 not started", and continues through Voiced and Combination. A sound-to-character review offered け, こ, か and く, all from one row. The goal screen lists the six target sets with 46, 58, 46, 58, 92 and 208 kana.
- **Bottom spacing fixed.** On this phone the system navigation bar covered the last row of the grid and would have covered the goal screen's save button, because those lists did not allow for it. The home, grid, kana detail and goal lists now add the system's bottom inset to their padding.
- **Sounds (task 10.5): accepted by the owner.** The pronunciations were judged acceptable. The owner finds the speaking speed too fast; a speech speed setting follows as its own change.

## Risks / Trade-offs

- **Seeding now writes to existing rows on real data** → Covered by the previous-state test, and by an in-place update on the phone after a fresh export, with the goal, card count and streak compared before and after.
- **Harder wrong options lower measured accuracy** → Accepted; the goal's accuracy target is unchanged and the learner was told. If it proves discouraging, the tiers can be loosened without touching data.
- **Predictable options** (が always shown with か and its row) → Random order within tiers and across positions; partners only appear once introduced, so the mix changes as the learner advances.
- **Lesson contents change mid-path for existing learners** → Only from the や row onward, and only in which kana share a lesson.
- **A lesson of six is longer than today's five** → Combination kana are rules applied to known shapes, so the load per kana is lower.
- **116 pattern-made mnemonics may read awkwardly or contain an error** → The integrity test checks structure; the text is reviewed by reading every entry once, and the learner can replace any of them.
- **An older app cannot import a newer backup** → It refuses with a clear message; the README notes it.
- **Device speech for ぢ, づ and combination kana is unverified** → Checked on the phone; the audio source is replaceable if a sound is wrong.

## Migration Plan

No schema migration. On the first launch after the update, seeding rewrites the payload and order of the 92 existing kana and adds 116. Existing goals, cards and reviews refer to item ids, which do not change. Rollback: an older build reads the new payloads (extra fields are ignored) and sees 208 kana in the new order, so a downgrade keeps working but treats all hiragana as one set; restoring a backup taken before the update is the clean way back.

## Open Questions

- Whether the 90% preset should be lower for voiced and combination goals, given harder options. Left at 90% until real use says otherwise.
