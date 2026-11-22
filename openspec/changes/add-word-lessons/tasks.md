## 1. Word items

- [x] 1.1 Add `ItemKind.word`, `WordPayload` and `Item.word`; make `Item.kana` and `Item.word` throw for the other kind
- [x] 1.2 Extend `ItemPayloadMapper` to store and read word payloads; make `SeedItem.defaultMnemonic` nullable and skip the mnemonic row for words
- [x] 1.3 Add `PromptType.wordToMeaningChoice` and `meaningToWordChoice`
- [x] 1.4 Tests: payload round trip, both getters, prompt type flags

## 2. Existing code tells the kinds apart

- [x] 2.1 Audit every reader of `item.kana` (kana grid and detail, kana status, goal progress, goal screen, daily kana quota, kana lesson, kana choice options, home, review) and filter by kind where it means "kana"
- [x] 2.2 Decide and document for each statistic whether it counts all cards (streak, daily review cap, study stats) or kana only (goal progress and accuracy)
- [x] 2.3 Add a test with words seeded to each affected use case and ViewModel, proving words do not leak into kana screens or goals

## 3. Bundling and syncing the list

- [x] 3.1 Add `data/words/words.json` to the assets in `pubspec.yaml`
- [x] 3.2 Implement `WordSeedLoader`: parse and validate the file's header and words into seed items; expose the list's dictionary date and current keys
- [x] 3.3 Make `syncSeedItems` write new items that have no mnemonic in one batch (it already read once, compared in memory and used one transaction)
- [x] 3.4 Run the word seed at startup after the kana seed; wire it in `app_dependencies.dart`
- [ ] 3.5 Measure the sync on the phone (first launch after update, and a later launch); move parsing to an isolate if it drops frames; record the numbers in design.md
- [x] 3.6 Tests: the real bundled file parses; every word's kana keys exist in the kana seed; sync is idempotent, updates a changed meaning, adds a new word, never removes, never touches learner data

## 4. Lessons

- [x] 4.1 Implement `GetNextWordLesson`: availability by introduced kana, current list only, quota of five a day, up to five words in order
- [x] 4.2 Implement `BuildWordChoiceOptions`: exclusions (same reading, shared meaning) and the four pools
- [x] 4.3 Extend `CompleteLesson` to create the two word cards for word items
- [x] 4.4 Confirm `GradeAnswer` creates no typed card for word cards
- [x] 4.5 Tests for 4.1 to 4.4, including marks, a retired word, few words known, and always four options

## 5. Word lesson screen

- [x] 5.1 Add the shared `WordText` widget: reading large, written form small beneath, scaling down to fit
- [x] 5.2 Add `ui/word_lesson/` with ViewModel and UI state: presentation with back and next, auto-speak and audio control, then the check with requeue, then completion
- [x] 5.3 Add the route and the done state returning home
- [x] 5.4 Tests: ViewModel flow (present, check, wrong answer requeued, complete, leave early); widget tests in three themes, small screen with large text, longest word and longest meanings

## 6. Reviews and home

- [x] 6.1 Extend the review ViewModel and UI state with the two word presentations and word feedback; speak the word after every word answer
- [x] 6.2 Render word prompts, word options and word feedback on the review screen with `WordText`
- [x] 6.3 Extend the home ViewModel and screen: primary action order, word lesson preview and secondary action
- [x] 6.4 Tests: review session mixing kana and word cards; each word prompt; feedback; home with every combination of review, kana lesson and word lesson

## 7. About, backup, docs

- [x] 7.1 Add `ui/about/` with the dictionary acknowledgement, dictionary date from the bundled list, list credits, the word data's licence and address, and a Licences row; link it from settings
- [x] 7.2 Make sure the bundled font licences appear in the licence page
- [x] 7.3 Backup: format version 3; drop and count unknown `word:` keys at read time; refuse other unknown keys; add word counts to the summary and the confirmation
- [x] 7.4 Tests: About screen content; backup round trip with words; version 1 and 2 files import; unknown word skipped and counted; unknown kana refused; an older reader refuses version 3
- [x] 7.5 Update `data/words/README.md` and the main README: the app now uses and bundles the list; describe word lessons and the About screen

## 8. Checks on the phone

- [ ] 8.1 The owner exports a backup before installing the new build
- [ ] 8.2 Run `flutter analyze` and `flutter test`; fix all issues; build and install the release
- [ ] 8.3 The owner checks: existing kana progress is intact; a word lesson is offered and reads well; words are spoken correctly for a sample; word cards appear in a review; the home screen is clear; the About screen shows the dictionary date
- [ ] 8.4 Record what the check found in design.md and fix what it turns up
