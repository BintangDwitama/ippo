## Context

The app teaches 211 kana as items of one kind. The model was built to take more: `Items` has a `kind` and a JSON `payload`, `Cards` pair an item with a prompt type stored by name, and scheduling, review records and backup all work per item key and per card. `data/words/words.json` (1,291 words, 240 KB) records for every word the keys of the kana needed to read it and a learning order.

Decisions from exploration, made by the owner: words unlock as their kana are learned; cards are word to meaning and meaning to word, both multiple choice; the written form is shown small on every word card; five new words a day, separate from the kana quota; goals stay kana-only; this change also brings the About screen. Deferred: a word browser, listening cards, typed answers, word goals, downloading newer data.

Constraints: offline; no secrets; layered architecture with repositories behind interfaces and one ViewModel per screen; fakes in tests.

## Goals / Non-Goals

**Goals:**

- Words appear as early as possible and practise the kana just learned.
- Word cards live in the same review session and schedule as kana cards.
- A learner with existing data updates without losing or changing anything.
- The app credits its sources as the dictionary's licence requires.

**Non-Goals:**

- Browsing or searching the word list.
- Listening-only cards, typed answers, mnemonics or example sentences for words.
- Goals, pace setting or statistics for words.
- Teaching kanji. The written form is shown for recognition only.
- Fetching word data over the network.

## Decisions

### 1. One source file, bundled where it lives

`pubspec.yaml` lists `data/words/words.json` as an asset. The app reads the same file the build script writes and the monthly job updates; there is no copy to keep in step. `overrides.json`, `preview.md` and the source lists are not bundled.

Alternative: copy into `assets/seed/`. Rejected: two files that must match, and a test would be needed only to police the copy.

### 2. Words are items of a second kind

- `ItemKind.word`; `WordPayload` with `reading`, `written` (nullable), `meanings`, `partOfSpeech`, `level` and `kanaKeys`.
- Key: `word:<id>` where id is the JMdict sequence number from the list. It survives rebuilds, which is what lets progress survive list updates.
- `sortOrder`: `100000 + order`. Kana orders end at 1301; the gap keeps "all items in teaching order" meaningful and leaves room.
- `Item.kana` stays, and `Item.word` is added. Each throws for the other kind, so a mix-up fails in tests instead of showing nonsense.
- `SeedItem.defaultMnemonic` becomes nullable; a word gets no mnemonic row.

No schema migration: `kind` and `promptType` are text columns holding enum names, and the payload is JSON.

**Every existing reader of items must choose a kind.** Nineteen files read `item.kana` today. Each is audited (task group 2): the kana grid, kana status, goal progress, daily kana quota, kana lesson, kana choice options, home and the review screen. Statistics that mean "reviews done" (streak, daily review cap) count all cards; anything that means "kana" filters by kind. This audit is the main risk of the change and is covered by tests that seed words into the existing use-case tests.

### 3. Loading and syncing 1,291 words at launch

A `WordSeedLoader` parses the asset into `SeedItem`s and calls the existing `syncSeedItems`. Parsing checks the header's `format` and `formatVersion` and fails loudly on a file it does not understand.

`syncSeedItems` today compares item by item, which is fine for 211. For 1,502 it must read all stored items once, compare in memory, and write only differences in one batch inside one transaction. First launch after the update inserts 1,291 rows; later launches write nothing.

Launch must not visibly slow down. The target on the owner's phone: first launch after update under one second for the sync, later launches under 100 ms. If parsing 240 KB of JSON on the UI thread drops frames, it moves to an isolate (`compute`). Measured in task 3.5 before deciding.

Words dropped from a later list stay in the database (the sync never removes). A learned word keeps its cards; an unlearned one would still be offered. To prevent that, the loader's set of current keys is kept in memory and the lesson chooser only offers words in it (decision 4).

### 4. Availability and the next word lesson

`GetNextWordLesson` takes all items and the current time:

1. introduced kana keys = keys of kana items with `introducedAt`;
2. available = word items not introduced whose `kanaKeys` are all in that set and whose key is in the current list;
3. quota left = 5 minus words introduced today (by `StudyCalendar.isSameDay`, as kana do);
4. the lesson = the first `min(5, quota left)` available words by `sortOrder`.

Marks are introduced by kana lessons like any kana, so きって waits for the small っ lesson with no special case.

The constants (five a day, five a lesson) live in the use case. No setting, no goal.

The list's order puts all level 5 words before level 4. Within a level it is ordered by the last kana needed, so the words offered right after a kana lesson are mostly ones that use the new row.

### 5. Word lesson screen

A new screen and ViewModel (`ui/word_lesson/`, route `/word-lesson`), not a mode of the kana lesson: the kana lesson is built around mnemonics, rows and rule cards, none of which apply.

Flow: present each word (auto-speak, back and next) → check (one word-to-meaning question per word, wrong ones requeued) → `CompleteLesson`. Leaving before the end changes nothing, as with kana.

Layout of a word, used in the lesson, in review prompts, in options and in feedback, as one shared widget `WordText`: reading in the kana font, written form beneath at a smaller size and lower emphasis. Sizes come from the design tokens; a long word (アクセサリー, 7 kana) must fit a small screen at large text scale, so the reading scales down to fit rather than wrapping.

Check options come from the same use case as review options (decision 7), with the lesson's own words counted as known.

### 6. Completing a lesson

`CompleteLesson` takes items of either kind and creates cards by kind: kana as today; words get `wordToMeaningChoice` and `meaningToWordChoice`. One transaction, as today.

### 7. Prompt types and options

`PromptType` gains `wordToMeaningChoice` and `meaningToWordChoice`; `needsAudio` and `isTyped` are false for both.

`BuildWordChoiceOptions(correct, allItems, random)` returns three wrong words:

- excluded: the same reading as the correct word; any meaning in common with it (compared case-insensitively);
- pool 1: introduced words, same part of speech;
- pool 2: introduced words, any part of speech;
- pool 3: words that are available by decision 4 but not yet introduced;
- pool 4: any other word of the list (reachable only in tests and odd states; guarantees four options).

Pools are shuffled and drawn in order until three are found. The same options serve both prompt types: shown as meanings for word to meaning, as words for meaning to word.

Why exclude shared meanings: 暑い "hot" and 熱い "hot to the touch" do not collide, but お父さん and 父 both mean "father", and offering one as a wrong answer for the other would be a trick. Why prefer the same part of speech: every verb's meaning starts with "to", so a lone verb among nouns gives itself away.

A meaning is displayed as the word's meanings joined with "; ".

No graduation: `GradeAnswer` creates a typed card only for kana, as today. The comment there about kana answers being plainly right or wrong holds for these choice cards too.

### 8. Review screen

The review ViewModel builds a per-card presentation by prompt type. Word cards add two variants to the UI state: prompt as `WordText` with meaning options; prompt as meanings with `WordText` options. Feedback for word cards always shows the word in full and speaks it, right or wrong; it is the only listening practice words get in this change.

Speaking after a correct answer must not slow the session: the next card may be advanced while the word is still being spoken, and a new sound interrupts the old one, as `SpeechRepository.speak` already does.

`BuildReviewSession` is unchanged: it works on cards and already separates cards of the same item.

### 9. Speaking a word

`SpeechRepository.speak(text)` already takes any text and applies the speed setting. Words are spoken from `reading`, never from `written`: a voice can misread kanji, and the reading is what is being taught. Risk: a voice may read a kana string oddly (a lone は as "wa"). Checked by ear on the phone for a sample of words (task 8.3); a per-word spoken form can be added to the payload later if any are wrong.

### 10. Home screen

Order of the primary action: review, kana lesson, word lesson, rest. Kana before words because kana unlock words. Whatever is not primary appears as a secondary action in that same order, each with its preview: kana characters as today; for words, the readings and "5 new words".

`HomeUiState` gains the word lesson (list of items). The rest message is unchanged.

### 11. About and sources

`ui/about/` with its own ViewModel, reached from a new settings row. Content:

- The JMdict acknowledgement in the wording the EDRDG licence gives, the project and licence page addresses, "CC BY-SA 4.0".
- The dictionary date, read from the bundled list's header through the word seed loader (exposed by a small `WordListInfo` value), not hard-coded.
- The JLPT lists: Jonathan Waller (CC BY), matched by Stephen Kraus (CC BY-SA 4.0), addresses.
- That the app's word list is a changed selection, shared under CC BY-SA 4.0, with the repository address of `data/words`.
- A "Licences" row opening Flutter's built-in licence page, which already carries package licences; the bundled font licences are registered with `LicenseRegistry` from `assets/fonts/licenses/` if they are not there already.

Addresses are shown as selectable text. No `url_launcher`: it would be a new dependency and a new way out of an offline app for four links.

### 12. Backup

- `BackupCodec.formatVersion` becomes 3. The file's shape does not change (items and cards are already listed by key and prompt type name); the bump exists so that an older app, which cannot parse the new prompt type names or find `word:` keys, says "needs a newer version" instead of failing obscurely. Versions 1 and 2 still import.
- Unknown keys: today any unknown key refuses the file. Now unknown keys beginning `word:` are dropped from the snapshot at read time, with their cards and reviews, and counted; any other unknown key still refuses. The count is part of `BackupSummary` and shown on the confirmation.
- `BackupSummary` gains word counts for the file and the phone; the existing "introduced" count becomes kana only.

### 13. Testing

- **Use cases**, with fakes: availability (all kana known, one missing, marks, retired word); quota and lesson size; `CompleteLesson` per kind; word choice options (each exclusion, each pool, always four); `GradeAnswer` creates no typed card for words.
- **Existing use cases with words present**: goal progress, kana status, kana lesson, kana options, daily quota, study stats each get a test seeded with words to prove words do not leak in.
- **Seed**: the loader parses the real bundled file; every word's `kanaKeys` exist in the kana seed; sync is idempotent and leaves learner data alone; a changed meaning is updated.
- **Backup**: round trip with words; version 2 file imports; unknown word skipped and counted; unknown kana refused.
- **Widgets**: word lesson flow; review screen with each word prompt; home with each combination of actions; About screen content; each in the three themes at small size and large text where layout is at risk (long words, long meanings).

## Risks / Trade-offs

- **A reader of `item.kana` is missed and crashes on a word** → The getter throws; the audit list is explicit; existing tests are rerun with words seeded.
- **Launch slows down** → One read, in-memory compare, one batch; measured on the phone; isolate if needed.
- **Review load grows faster than the learner expects**: up to ten new cards a day on top of kana → The daily review cap already bounds a day. Five a day is a constant that can become a setting.
- **Automatically chosen meanings mislead** → 181 were corrected and the owner has read the preview; a wrong one found while studying is fixed in `overrides.json` and reaches the app with the next build, without touching progress.
- **Meaning-to-word is too easy early on**, when the four options are the only words known → Accepted; it corrects itself within days.
- **The voice misreads some kana strings** → Checked by ear; a spoken form per word is the fallback.
- **Showing kanji may intimidate** → It is small and never asked about. If it distracts in use, hiding it on words with a unique reading is a small change.
- **A word removed from the list stays in the database** → Harmless: learned ones keep working, unlearned ones are not offered.
- **Share-alike data now ships inside the app** → The About screen and the repository notices give the required credit. The licence of the app's own code remains the owner's open decision and is not changed here.

## Migration Plan

No database migration. On first launch after the update the word items are added; existing kana, cards, goals and settings are untouched. Backups written from then on are version 3.

Rollback: an older build cannot read items of kind `word`, so going back means reinstalling the older build and importing a backup made before the update. The owner exports a backup before installing (task 8.1).

## Open Questions

- Whether five words a day feels right alongside kana lessons. Answered by a week of use; the constant is one line.
- Whether the home screen with three actions (review, kana lesson, word lesson) stays clear on a small phone. Judged on the device in task 8.
