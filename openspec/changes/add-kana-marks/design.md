## Context

Every kana in the app is an item with a reading: lessons present it, then quiz it; completing a lesson creates two multiple-choice cards per kana; reviews ask "how is this read?" or "which kana makes this sound?". `KanaGroup` has three values (basic, voiced, combination) and `GoalTargetSet.includes` treats everything that is not basic as "extended". Three places speak a kana by passing `kana.character` to `SpeechRepository.speak`: the lesson, review and kana detail ViewModels.

っ, ッ and ー break the "has a reading" assumption. Alone they are silent; they change the kana next to them. Asking "how is っ read?" has no answer, and playing "っ" plays nothing useful.

This change exists to unblock the next stage, where a word unlocks once every kana in it has been learned. It is deliberately small.

## Goals / Non-Goals

**Goals:**
- The three marks can be learned, in the right place on the path, and are recorded as learned.
- The learner hears what each mark does.
- No screen asks a question about a mark that has no answer.

**Non-Goals:**
- Drill cards for hearing doubled or long sounds. They need a new kind of question whose options are spellings, not kana; worth doing, but not needed to unblock words.
- Hiragana long vowels, which use ordinary kana (おかあさん).
- Small vowel kana for foreign sounds (ファ, ティ).

## Decisions

### 1. Marks are kana items in a fourth group

```json
{"script": "hiragana", "character": "っ", "romaji": "small tsu", "alt": [],
 "key": "hiragana:sokuon", "group": "mark", "row": "mark", "family": "small tsu",
 "lookalikes": [], "order": 300, "sample": "きて、きって",
 "mnemonic": "A small つ. It has no sound of its own: it doubles the consonant after it, with a short pause. きて is \"kite\"; きって is \"kitte\"."}
```

| Mark | Key | Order | Label | Spoken sample |
|---|---|---|---|---|
| っ | `hiragana:sokuon` | 300 | small tsu | きて、きって |
| ッ | `katakana:sokuon` | 1300 | small tsu | カト、カット |
| ー | `katakana:choon` | 1301 | long mark | ビル、ビール |

`KanaGroup` gains `mark`. The `romaji` field holds the mark's name, since it is what every screen shows under a kana; nothing parses it. Keys are stated, as for ぢ and づ.

Keeping marks as kana items means seeding, the grid, lessons, goals, backups and the detail screen work without a parallel model. Alternative considered: a separate item kind. Rejected: every one of those features would need a second branch for three items.

### 2. A spoken sample replaces the character for speech

`KanaPayload` gains an optional `sample`, and a getter `spoken` that returns the sample when there is one and the character otherwise. The three ViewModels that speak a kana pass `kana.spoken`. For ordinary kana nothing changes.

The sample is a pair, without and with the mark, separated by a comma so the voice pauses. Hearing the contrast is the point; the mark alone is silent.

### 3. No cards and no quiz for a mark

- `CompleteLesson` marks every kana of the lesson as introduced and creates the two starting cards only for kana that are not marks.
- The lesson's quiz covers only the kana that can be asked. A lesson made only of marks goes from the last presentation straight to completion; its last button reads "Finish" instead of "Start the quiz", and the completion message does not mention reviews.
- `GetKanaStatus` reports a mark as known once it is introduced. The existing rule would leave it "learning" for ever, since it has no cards to mature.
- `BuildChoiceOptions` leaves marks out of the wrong options. A mark is never the correct answer because it has no card.

`LessonPresenting` gains `hasQuiz` and `LessonComplete` gains `hasReviewCards`, so the screen chooses its wording from state.

### 4. Position on the path

The seed orders place each mark after its script's combination kana. `GetNextLesson` already cuts a lesson at a change of group, so っ is a lesson of one and ッ with ー a lesson of two; no change to that use case.

`GoalTargetSet.includes` already treats every non-basic kana as extended, so the marks fall into the voiced-and-combination sets and the all-kana set with no code change. The counts shown become 59, 60 and 211. A learner on such a goal sees it grow by one or two; nobody is on one yet, and the alternative (marks in no goal) would mean a learner with a goal is never offered them.

### 5. Grid

A fourth section, Marks, follows Combination. Marks are laid out left to right in order, not by vowel column, since their labels are names, not readings.

### 6. Backup

Unchanged format and version. A backup recording a mark as introduced names a key an older app lacks, which that app already refuses with "does not match this version of Ippo".

### 7. Testing

- **Seed**: 211 entries; one hiragana and two katakana marks; each mark has a sample, a stated key and comes after its script's combination kana; the existing integrity checks still hold.
- **Seeding**: a database with 208 kana and learner data gains three items and keeps the data.
- **Domain**: `spoken`; `CompleteLesson` with a mark (introduced, no cards) and with a mixed lesson; `GetKanaStatus` for a mark; `BuildChoiceOptions` never offers a mark; target set counts of 59, 60 and 211; the full path walk ends each script with its marks.
- **Lesson ViewModel**: a marks-only lesson has no quiz and completes; speech uses the sample.
- **UI**: the grid's fourth section; a marks lesson from home to completion; small screen with large text in each theme.

### 8. Notes from implementation

- **`KanaPayload.isMark`** is the one question the rest of the code asks; `CompleteLesson`, `GetKanaStatus`, `BuildChoiceOptions`, the lesson ViewModel and the grid each use it.
- **The sample is stored in the payload only for marks.** Ordinary kana carry no `sample` field at all.
- **The quiz counts only the kana it asks about,** so the progress shown during a quiz is out of the askable kana, not the whole lesson.
- **A test checks each sample pair mechanically:** removing the mark from the second word must give the first.
- **Path length:** walking every lesson with no goal now takes 44 lessons (42 before): one more for っ and one for ッ with ー.
- **No change was needed in `GetNextLesson` or `GoalTargetSet`.** The existing rules (cut a lesson at a change of group; everything not basic is extended) already place and count the marks.

## Risks / Trade-offs

- **A rule read once is easily forgotten, and nothing reviews it** → Words in the next stage use the marks constantly; a hearing drill is noted as a follow-up.
- **The device voice may not make the contrast audible** (きて against きって) → Judged by ear on the phone; the samples are data and can be swapped for clearer pairs.
- **Extended goals grow by one or two kana** → Accepted; no such goal exists yet.
- **"small tsu" as a label under a tile is longer than a reading** → Tiles already scale their content; checked in the small-screen test.

## Migration Plan

No migration. Seeding adds the three items on the next launch.

Going back to an older build after this update is not supported: the older build cannot read a kana whose group is `mark` and would fail when loading the kana. The way back is to reinstall the older build and import a backup taken before the update.
