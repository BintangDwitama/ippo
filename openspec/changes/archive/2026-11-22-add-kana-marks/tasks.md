## 1. Model and seed

- [x] 1.1 Run `flutter analyze` and `flutter test` to confirm a clean baseline
- [x] 1.2 Add `KanaGroup.mark`, an optional `sample` and the `spoken` getter to `KanaPayload`; update `ItemPayloadMapper` and the seed parser to read and write `sample`
- [x] 1.3 Add the three marks to `assets/seed/kana.json` with stated keys, orders 300, 1300 and 1301, names, samples and rule mnemonics
- [x] 1.4 Update the seed integrity tests: 211 entries, one hiragana and two katakana marks, each with a sample and placed after its script's combination kana
- [x] 1.5 Test seeding over a database holding the 208 kana and learner data: three items are added and the data is unchanged

## 2. Domain rules

- [x] 2.1 `CompleteLesson`: introduce every kana of the lesson, create cards only for kana that are not marks; with tests for a marks lesson and a mixed lesson
- [x] 2.2 `GetKanaStatus`: a mark is known once introduced; with tests
- [x] 2.3 `BuildChoiceOptions`: never offer a mark as an option; with tests
- [x] 2.4 Tests: `GoalTargetSet` counts of 59, 60 and 211; goal progress totals; the full path walk ends each script with its marks

## 3. Speech

- [x] 3.1 Speak `kana.spoken` in the lesson, review and kana detail ViewModels
- [x] 3.2 Tests: an ordinary kana is spoken as its character and a mark as its sample

## 4. Lesson flow

- [x] 4.1 Lesson ViewModel: quiz only the kana that are not marks; complete straight after presenting when there is nothing to quiz; add `hasQuiz` to `LessonPresenting` and `hasReviewCards` to `LessonComplete`
- [x] 4.2 Lesson screen: the last button reads "Finish" when there is no quiz, and the completion message leaves out reviews when no cards were created
- [x] 4.3 ViewModel tests: a marks-only lesson has no quiz, introduces the marks and creates no cards; an ordinary lesson is unchanged

## 5. Screens

- [x] 5.1 Kana grid: a Marks section, laid out left to right; update the ViewModel, the screen and their tests
- [x] 5.2 Widget tests: a marks lesson from home to completion; the grid's four sections; a small screen with large text in each theme

## 6. Checks

- [x] 6.1 Run `flutter analyze` and `flutter test`; fix all issues
- [x] 6.2 Update README.md: 211 kana and the marks

## 7. On the phone

- [x] 7.1 Build a release APK, install it over the app, and the owner confirms progress is intact
- [x] 7.2 The owner opens っ, ッ and ー from the kana grid, plays each sound, and says whether the difference within each pair can be heard; change the samples if not
