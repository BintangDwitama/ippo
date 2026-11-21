## 1. Baseline

- [x] 1.1 Run `flutter analyze` and `flutter test` to confirm a clean baseline
- [x] 1.2 Copy the current `assets/seed/kana.json` to `test/fixtures/kana_seed_v1.json` as the "previous state" for seeding tests

## 2. Kana model

- [x] 2.1 Add `KanaGroup` (basic, voiced, combination) and the fields `group`, `row`, `family` and `lookalikes` to `KanaPayload`, with defaults for payloads that lack them
- [x] 2.2 Update `ItemPayloadMapper` to encode and decode the new fields, with tests including a payload in the old shape
- [x] 2.3 Update the seed parser: read the new fields and an optional `key`, defaulting to `script:romaji`; reject an unknown group; with tests
- [x] 2.4 Update the test builders (`kanaItem`, `kanaItems`) to set group and row

## 3. Seed content

- [x] 3.1 Add `group`, `row`, `family` and `lookalikes` to the 92 existing entries and renumber katakana to start at 1000
- [x] 3.2 Add the 25 voiced and 33 combination hiragana with readings, accepted alternative romanisations, rows, families, orders and rule-style mnemonics; ぢ and づ with their own keys
- [x] 3.3 Add the same 58 katakana
- [x] 3.4 Read every new mnemonic once and correct any that is wrong or awkward
- [x] 3.5 Seed integrity test on the real asset: 208 entries, unique keys, unique script and character pairs, counts per group, rows of at most five, orders ascending along the path, lookalikes and families resolve, the 92 original keys present

## 4. Seeding

- [x] 4.1 Replace `insertSeedItems` with `syncSeedItems` in `ItemRepository`, `DriftItemRepository` and the fake: insert missing kana, update payload, order and default mnemonic of existing kana when they differ, write nothing else
- [x] 4.2 Test seeding over the previous state: a database seeded from the version 1 fixture with introduced kana, cards, reviews, a goal and a learner mnemonic keeps all of that after syncing the new seed, gains 116 kana, and has updated payloads and orders
- [x] 4.3 Test that a second sync writes nothing, and that a learner-edited mnemonic survives a changed default
- [x] 4.4 Update `KanaSeedLoader` and `main.dart` to call the sync

## 5. Goals

- [x] 5.1 Add `hiraganaExtended`, `katakanaExtended` and `everything` to `GoalTargetSet`, change `includes` to take the kana, and add a kana count per target set; with tests
- [x] 5.2 Update `GetNextLesson` and `GetGoalProgress` to use the new `includes`; progress totals of 46, 58, 92 and 208 in tests
- [x] 5.3 Add the next-goal suggestion along the path and use it in `GoalViewModel`, with tests
- [x] 5.4 Replace the goal screen's three-segment control with a list of the six target sets and their counts
- [x] 5.5 Update ViewModel and widget tests for the goal screen

## 6. Lessons by rows

- [x] 6.1 Change `GetNextLesson` to cut lessons as whole rows up to six kana, never mixing scripts or groups
- [x] 6.2 Tests: full rows, や ゆ よ alone, わ を ん together, paired combination rows, a partly introduced row, the path across groups and scripts, and the existing quota cases
- [x] 6.3 Update lesson ViewModel and navigation tests that assume five kana

## 7. Wrong options

- [x] 7.1 Change `BuildChoiceOptions` to rank kana the learner has met: partners, look-alikes, same row, then others, random within each
- [x] 7.2 Tests: each tier, short tiers, the first lesson, only introduced kana, same-reading exclusion, variation between calls with different random seeds

## 8. Screens

- [x] 8.1 Make `KanaText` scale down to the available width
- [x] 8.2 Group the kana grid into Basic, Voiced and Combination sections in `KanaGridUiState`, `KanaGridViewModel` and the screen, with ViewModel tests
- [x] 8.3 Widget tests in each theme at 360 by 640 logical pixels and text scale 1.3: a lesson and a review question with a combination kana, the sectioned grid, and the goal screen's six options

## 9. Backup

- [x] 9.1 Raise `BackupCodec.formatVersion` to 2 and read versions 1 and 2
- [x] 9.2 Tests: the version 1 fixture and a new version 2 fixture decode; version 3 is refused as newer; a version 1 hiragana goal covers 46 kana after import

## 10. Verification

- [x] 10.1 Run `flutter analyze` and `flutter test`; fix all issues
- [x] 10.2 Update README.md: 208 kana, the teaching path, and that older versions cannot import newer backups
- [ ] 10.3 On the phone: export a backup, note the goal progress, cards due and streak, install the release build over the app, and confirm all three are unchanged
- [ ] 10.4 On the phone: confirm the grid shows three sections, a wrong option for a basic kana is now a look-alike or row-mate, and the goal screen lists six target sets
- [ ] 10.5 On the phone: play the sound of が, ぢ, づ, ぱ, きゃ and しょ from the kana detail screen and judge each
