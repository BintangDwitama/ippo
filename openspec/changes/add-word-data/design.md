## Context

The repository holds a Flutter app with no tooling scripts and no automation: there is no `tool/` folder and no `.github/` folder. Content the app owns lives in `assets/seed/kana.json`, with 211 kana, each carrying a stable key (`hiragana:ka`), a group, a row and a teaching order.

Facts established before this design:

- **JMdict** is published by the Electronic Dictionary Research and Development Group (EDRDG) under Creative Commons Attribution-ShareAlike 4.0. The licence covers files derived from it. Software using it need not be open source. Publishing extracts such as vocabulary lists requires clearly acknowledging the source. An app using the files must acknowledge them on a separate About or Sources screen and must have a procedure for regularly updating to recent versions.
- **jmdict-simplified** republishes JMdict weekly as JSON under the same licence. Each word has an id, kanji forms and kana forms (each with a `common` flag and tags; kana forms say which kanji forms they apply to), and senses with parts of speech, miscellaneous tags and glosses. It has no beginner-level information.
- **The beginner list** (the reconstructed vocabulary of the first two exam levels, compiled by Jonathan Waller) is described by several projects that republish it as released under Creative Commons Attribution. The author's site no longer resolves, so the original statement could not be read. One project maps the list to JMdict entry ids.

Decisions from exploration: dictionary as the source from the start; the beginner list supplies selection and order; one word per reading; the monthly rebuild is part of this change; nothing ships in the app yet.

## Goals / Non-Goals

**Goals:**
- A word list good enough for a beginner to learn from, that a person can read through and correct.
- The same inputs always produce the same file, so a rebuild shows only real changes.
- Every word says which kana it needs, so the app can unlock it without re-deriving anything.
- Sources credited as their licences ask, from the first commit that contains their data.
- The list stays current without anyone remembering to rebuild it.

**Non-Goals:**
- Any change to the app: no asset, no screen, no permission.
- Kanji as things to learn. A word records its written form for display only.
- Example sentences, pitch accent, verb conjugations.
- Meanings in languages other than English.
- More than one word per reading.

## Decisions

### 1. Layout

```
tool/words/
  build_words.dart        entry point: dart run tool/words/build_words.dart
  src/                    pure logic, one concern per file
data/words/
  words.json              generated; the product of this change
  preview.md              generated; words unlocked by each row of kana
  overrides.json          hand-edited corrections
  sources/                the beginner list as vendored, with its notice
  README.md               sources, licences, date of the data, how to rebuild
  LICENSE                 CC BY-SA 4.0 notice for the files in this folder
test/words/               tests for the logic and for the generated file
.github/workflows/update-words.yml
```

The word file lives in `data/`, not `assets/`, and is not declared in `pubspec.yaml`, so it cannot be bundled by accident. The next change moves or declares it when the app starts using it.

The script is Dart, like the rest of the repository, and reads `assets/seed/kana.json` directly so that "readable with the app's kana" always means the kana the app really has.

### 2. Inputs

- **Dictionary**: the English JMdict file of the latest jmdict-simplified release, full version. The script takes the path of the unpacked file (`--dictionary`); it does not download. Fetching is one command in the workflow and one manual step in `data/words/README.md`, which keeps network code and a zip dependency out of the script.
- **Beginner list**: vendored under `data/words/sources/` with its attribution, because its original home has already disappeared once. The first task confirms which republished copy to take and what licence statement accompanies it.

The full dictionary file is used, not the common-only one, so that no beginner word is lost to a missing "common" mark.

### 3. Matching the list to the dictionary

The vendored list already carries a JMdict id for every row (the `jmdict_seq` column), under a licence that allows reuse, so the script looks entries up by id and does no matching of its own. A row whose id is not in the dictionary is listed in the preview as not found. A row matched to the wrong entry (ten were found, for example コップ pointing at "cop") is redirected with a `useEntry` override.

### 4. What is recorded for a word

```json
{
  "id": "1578850",
  "reading": "あか",
  "written": "赤",
  "meanings": ["red"],
  "partOfSpeech": "noun",
  "level": 5,
  "order": 37,
  "kana": ["hiragana:a", "hiragana:ka"]
}
```

- `id`: the dictionary entry's id, as a string. The first task confirms that these are JMdict's own sequence numbers and stable across releases; if they are not, the key becomes level plus reading, which rule 6 makes unique.
- `reading`: the reading the list gives, when the dictionary entry has it; else the entry's first common kana form, else its first.
- `written`: the spelling the list gives, when the entry has it as an ordinary form the reading applies to (not tagged rare, search-only, outdated or irregular); else the entry's first ordinary form, preferring a common one. Null when the list gives the word in kana. The list's maintainer already chose the spelling a beginner meets, which is a better signal than the dictionary's "usually kana" tag.
- `meanings`, in this order of preference: (1) *endorsed*: the dictionary's glosses, from any unrestricted sense that applies to this reading and spelling, that equal a term of the list's own definition (ignoring case and a leading article), two at most; (2) *first sense*: the first two glosses of the first such sense, preferring glosses without a parenthesised explanation, because cutting the parentheses from "good (tasting)" leaves "good"; (3) the list's definition. Three at most after overrides. The first sense alone proved a poor choice: おいしい came out as "good; nice". The preview flags every word that fell to (2).
- `partOfSpeech`: one of noun, verb, i-adjective, na-adjective, adverb, pronoun, expression, other, mapped from the dictionary tags of the sense the first meaning came from.
- `level`: 5 or 4.
- `kana`: the keys of the app's kana needed to read `reading`, in order of first use, without repeats.

The file's header records its format name and version, the dictionary's date, and its sources.

### 5. Reading a word as the app's kana

The reading is split left to right, taking two characters when they form one of the app's combination kana (きゃ) and one otherwise. The small っ, ッ and the long mark ー are kana the app teaches and are matched like any other. A word is dropped when any piece is not one of the 211 kana: for example small vowel kana used for foreign sounds.

The split uses the seed file, so a kana added to the app later makes more words eligible on the next rebuild with no change to the script.

### 6. Selection rules, in order

1. The word is on the beginner list at level 5 or 4 and matched to a dictionary entry.
2. It has at least one sense, applying to its reading and spelling, that is not tagged archaic, obsolete, rare, vulgar or derogatory (`arch`, `obs`, `rare`, `vulg`, `derog`, `X`). Senses so tagged are never a source of meanings.
3. Its reading splits into the app's kana (decision 5).
4. Overrides are applied: an override may exclude the word, replace its meanings or written form, or name the dictionary entry to build it from.
5. Among words with the same reading, one is kept: the lower exam level first, then the entry marked common, then the smaller id. The others are listed in the preview as set aside.

### 7. Order

`order` numbers the kept words from 1 by: level (5 before 4); then the latest teaching position among the kana the word needs, so words readable earlier come earlier; then the number of kana in the reading; then the reading itself. Every term is derived from the inputs, so the order is stable.

The app will not teach in this order blindly: a word is offered only once its kana are learned. The order decides which unlocked word comes first.

### 8. Overrides

`data/words/overrides.json` maps the id of a list row to any of `exclude` (true), `meanings`, `written`, `useEntry` and a free-text `note`. Any other field is refused. The script fails if an override names an id that is not a candidate, so a stale override is noticed.

Because the dictionary carries no frequency rank, the same-reading tie-break is arbitrary between two words of one level. Where it kept the clearly less common word, an `exclude` on that word hands the reading to the other (seven cases, for example 飴 excluded so that 雨 is kept).

### 9. The script checks its own output

Before writing, the script verifies: ids unique; readings unique; every kana key exists in the seed; meanings non-empty and without parentheses; `order` runs from 1 without gaps; levels are 5 or 4; the word count lies within a sanity range. A failure stops the run with a message and writes nothing. The same checks run as tests against the committed file.

Output is written with sorted, stable formatting, one word per line, so a rebuild produces a small, readable diff.

### 10. Preview

`data/words/preview.md` is generated alongside the word file. For each row of kana in teaching order it lists the words that become readable once that row is learned, with reading, written form and meanings, and the running total. It ends with the words set aside by the same-reading rule and the list entries not matched. It is the document the owner reviews.

### 11. Attribution

- `data/words/README.md` names both sources, their authors, their licences and the two EDRDG project links the licence permits quoting; states the dictionary date of the committed file; and explains how to rebuild.
- `data/words/LICENSE` states that the files in the folder are under Creative Commons Attribution-ShareAlike 4.0.
- The repository's main README gains a short section pointing to these.

The acknowledgement inside the app (a separate About screen) is required once the app uses the data, and belongs to the next change.

### 12. Monthly rebuild

A workflow runs on the fifth day of each month and on manual request. It installs Flutter, runs the script and the word tests, and, if anything under `data/words/` changed other than the dictionary date, pushes a branch and opens a pull request with the dictionary date in its title. A newer dictionary that changes no word proposes nothing, so the committed date is the date of the last dictionary that changed the list.

A pull request, not a direct commit, because a change in the dictionary can change a meaning the learner sees; the diff is the review. Opening a pull request from a workflow needs the repository setting that allows it; the owner switches it on (task 6.3). Without it the job still pushes the branch and the pull request is opened by hand.

Actions are pinned to released versions. The workflow needs only the repository's own token.

This is the update procedure the dictionary's licence asks for. Its effect reaches learners when the app ships a newer file, and later when the app can fetch one.

### 13. Testing

- **Logic**, with a small hand-made dictionary and list as fixtures: splitting readings (plain, combination, small っ, long mark, an unreadable character); each selection rule; the same-reading rule and its tie-breaks; meanings (two glosses, parentheses removed); part-of-speech mapping; overrides including a stale one; order.
- **The committed file**: the checks of decision 9, plus that every word's `kana` matches a fresh split of its reading.
- **The preview**: every kept word appears exactly once.

## Findings during implementation

**Sources (tasks 1.1 to 1.4)**

- Dictionary: jmdict-simplified release `3.6.2+20261116213322`, file `jmdict-eng-3.6.2.json`, 118 MB unpacked (11.5 MB zipped), `version` 3.6.2, `dictDate` 2026-11-16, 219,127 entries.
- Ids are JMdict's own sequence numbers (id 1258330 is 犬, as in JMdict), so they are used as word ids. No fallback key is needed.
- Tags, from the file's tag table: `arch` archaic, `obs` obsolete, `rare` rare, `vulg` vulgar, `derog` derogatory, `X` rude or X-rated, `uk` usually written in kana; on kanji forms `rK` rare, `sK` search-only, `oK` outdated, `iK` irregular, `ateji`.
- Beginner list: `original_data/n5.csv` (684 rows) and `n4.csv` (640 rows) of `stephenmk/yomitan-jlpt-vocab` at commit `b062d4e`. Repository licence CC BY-SA 4.0; its README states that Jonathan Waller's original lists are CC BY. The mapping to JMdict ids is part of that repository and is used.

**Result (task 4.2)**, from the dictionary of 2026-11-16:

- 1,253 words kept. Left out: 5 need a kana the app does not teach (パーティー, フィルム, フォーク, チェック, ファックス), 1 is obsolete (看護婦), 7 excluded by a correction and 31 set aside by the same-reading rule. No row was missing from the dictionary.
- Meanings: 964 endorsed, 168 corrected by hand, 121 from the first sense and flagged in the preview.
- Readable after each of the first eleven rows of hiragana (あ, か, さ, た, な, は, ま, や, ら, わ, ん): 13, 37, 81, 159, 208, 244, 325, 362, 554, 590, 662.

**Review (task 4.3)**: every one of the 287 words that first fell to the first sense was read against the list's definition; 168 were corrected. The 964 endorsed meanings were not read one by one. At least one was wrong (厚い came out as "kind; deep"), so the owner's read of the preview still matters.

## Risks / Trade-offs

- **The beginner list's licence rests on secondhand statements** → Credited to its author under the stated licence; the source notice says how the licence was established. If the author's own statement surfaces and differs, the list is the only thing to replace: the fallback is the dictionary's own "common" marks.
- **Dictionary ids may not be the stable sequence numbers assumed** → Checked first. The fallback key is level plus reading.
- **Automatically chosen meanings will sometimes be poor or too narrow** → The owner reviews the preview; overrides fix what is found; more will be found while studying.
- **Too few words are readable in the first weeks**, with only ten or twenty kana known → The preview shows the count per row before anything ships. If it is thin, a rule can be loosened (for example admitting the next level early).
- **One word per reading drops common words.** It sets aside 38 words, among them 着る to wear, 鼻 nose, 箸 chopsticks, 風邪 a cold, 髪 hair, 日 day and 熱い hot. This is a larger loss than expected at proposal time → The preview lists them all. Whether to keep homophones as separate words is put to the owner before the word screens are built; the word id is already unique without the rule.
- **A monthly change in the dictionary alters a meaning unexpectedly** → It arrives as a pull request with a diff.
- **The dictionary's JSON format may change** → The script checks the file's version field and stops with a clear message on one it does not know.
- **A large download in a scheduled job** → One 12 MB file a month, kept only for the run.

## Migration Plan

None. Nothing in the app changes. Rollback is deleting the new folders and the workflow.

## Open Questions

- Whether the repository needs an explicit licence for its code now that it contains data under a share-alike licence. The data folder states its own licence; the code's licence is the owner's decision and is not made here.
