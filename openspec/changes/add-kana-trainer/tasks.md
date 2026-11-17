## 1. Version control and project setup

- [x] 1.1 Set the git identity: `user.name` = `BintangDwitama`, `user.email` = `bintangdwitama010516@gmail.com`
- [x] 1.2 Run `git init` with branch `main`; add a `.gitignore` excluding `.idea/` and `.claude/settings.local.json`; make the first commit containing `openspec/`, `.claude/commands/` and `.claude/skills/`
- [x] 1.3 Create a public GitHub repository named `ippo` under the `BintangDwitama` account, add it as `origin`, and push `main`
- [ ] 1.4 Run `flutter doctor` and fix any Android toolchain issues (Android SDK, `adb` on PATH, a connected device or emulator)
- [x] 1.5 Create the Flutter project at the repository root with package name `ippo` and organisation `com.bintangdwitama` (application id `com.bintangdwitama.ippo`; Android and iOS platforms; only Android is built); merge Flutter's generated `.gitignore` with the entries from 1.2 and add `*.g.dart`
- [x] 1.6 Add dependencies: `provider`, `go_router`, `drift`, `drift_flutter`, `fsrs`, `flutter_tts`, `flutter_local_notifications`, `timezone`; dev: `drift_dev`, `build_runner`
- [x] 1.7 Create the folder structure from the design (`ui/`, `domain/`, `data/`, `routing/`, `test/fakes/`) and enable strict lints in `analysis_options.yaml`
- [ ] 1.8 Confirm the empty app builds and runs on the Android device

## 2. Early risk checks

- [ ] 2.1 Spike: play single kana (ã‚, ã‹, ã—, ã¤, ã‚“, ã¯) with `flutter_tts` on the Android phone and judge the quality; record the result in design.md and decide device voice or bundled recordings
- [x] 2.2 Spike: verify the Dart `fsrs` package (maintenance, API, intervals for a short good/again sequence look sensible); if unsuitable, plan `Sm2Scheduler` instead and update design.md

## 3. Domain models and scheduler

- [x] 3.1 Define domain models: `Item`, `KanaPayload`, `Mnemonic`, `Card`, `PromptType`, `SchedulingState`, `Rating`, `ReviewRecord`, `Goal`, `KanaStatus`
- [x] 3.2 Define the `Scheduler` interface and implement `FsrsScheduler` (90% retention, time passed in)
- [x] 3.3 Unit tests for `FsrsScheduler`: new card is due immediately, good lengthens the interval, again brings it back the same day and increments lapses
- [x] 3.4 Create `FakeScheduler` in `test/fakes/`

## 4. Data layer

- [x] 4.1 Define the drift database `AppDatabase` (schema version 1) with tables `items`, `mnemonics`, `cards`, `review_records`, `goals`, `settings`, including the unique constraints on `items.key` and `cards(item_id, prompt_type)`
- [x] 4.2 Define repository interfaces: `ItemRepository`, `MnemonicRepository`, `CardRepository`, `ReviewRepository`, `GoalRepository`, `SettingsRepository`, `SpeechRepository`, `ReminderRepository`, with `get{Model}Stream` methods where the UI observes data
- [x] 4.3 Implement the drift-backed repositories with row-to-domain mappers, including the kana payload mapper
- [x] 4.4 Repository tests against an in-memory drift database (create, read, stream updates, persistence of card state and review records)
- [x] 4.5 Create fakes for every repository in `test/fakes/`

## 5. Kana content

- [x] 5.1 Write `assets/seed/kana.json`: 46 hiragana and 46 katakana with romaji, accepted alternative romanisations, gojÅ«on order, and an original default mnemonic each
- [x] 5.2 Implement the seed loader (runs on first launch, transactional, safe to run twice) and a test that seeding twice yields exactly 92 items
- [x] 5.3 Implement mnemonic editing in `MnemonicRepository`: save learner text, reject blank text, restore default; with tests
- [x] 5.4 Implement the `GetKanaStatus` use case (not started, learning, known) with tests

## 6. Speech

- [x] 6.1 Implement `TtsService` and `TtsSpeechRepository` (Japanese voice detection, speak, stop, new request interrupts the previous one), or the bundled-recordings implementation if task 2.1 decided so
- [x] 6.2 Implement the one-time "install a Japanese voice" notice state in `SettingsRepository`

## 7. Lesson use cases

- [x] 7.1 Implement `GetNextLesson`: next batch of up to five kana in gojÅ«on order, hiragana before katakana, limited by the remaining daily quota; with tests
- [x] 7.2 Implement `BuildChoiceOptions`: one correct option plus three from the same script, preferring introduced kana; with tests including the first lesson
- [x] 7.3 Implement `CompleteLesson`: in one transaction mark kana introduced and create both multiple-choice cards per kana; with tests, including that an abandoned lesson writes nothing

## 8. Review use cases

- [x] 8.1 Implement `CheckTypedAnswer` (case, whitespace, alternative romanisations) with tests
- [x] 8.2 Implement `BuildReviewSession` (drop listening cards without a voice, most overdue first up to the cap, interleaved shuffle, no same-kana neighbours, injected random source) with tests
- [x] 8.3 Implement `GradeAnswer`: reschedule through `Scheduler`, write the review record, update `consecutive_correct`, create the typed card at three; in one transaction; with tests for graduation and a broken streak
- [x] 8.4 Implement in-session requeue of wrongly answered cards and the session summary calculation (count, first-attempt accuracy) with tests

## 9. Goal use cases

- [x] 9.1 Implement goal creation and validation (preset, target set, accuracy 50% to 100%, deadline at least one day) with tests
- [x] 9.2 Implement `CalculateDailyQuota` with tests for the even pace, falling behind and nothing remaining cases
- [x] 9.3 Implement `GetGoalProgress` (introduced count, 7-day first-attempt accuracy, days remaining, achieved or missed) with tests
- [x] 9.4 Implement `GetStreak` derived from review records and lesson dates, with tests
- [x] 9.5 Implement the daily review cap setting and its use in `BuildReviewSession`
- [x] 9.6 Implement `NotificationService` and `ReminderRepository` (daily local notification at a chosen time, permission request on enable, cancel on disable)

## 10. App shell

- [ ] 10.1 Wire services, repositories and use cases with `provider` in `main.dart`, using constructor injection
- [ ] 10.2 Configure `go_router` routes: home, lesson, review, kana grid, kana detail, goal, settings
- [ ] 10.3 Create the app theme and shared widgets (large kana display with a Japanese-capable font, audio button, choice button, progress bar)

## 11. Screens and ViewModels

- [ ] 11.1 Home: `HomeViewModel` and `HomeUiState` (due count, lesson availability, goal progress, streak, next due time) and screen
- [ ] 11.2 First-launch goal setup: preset offered, adjustable, with validation messages
- [ ] 11.3 Lesson: `LessonViewModel` with sealed `LessonUiState` (presenting, quiz, feedback, complete) and screen
- [ ] 11.4 Review: `ReviewViewModel` with sealed `ReviewUiState` (question for each prompt type, feedback, summary) and screen, including the romaji text field for typed cards
- [ ] 11.5 Kana grid and kana detail: status per kana, script switch, mnemonic edit and restore, audio button
- [ ] 11.6 Goal screen: progress, edit, achieved and missed states with the offer of a new or extended goal
- [ ] 11.7 Settings: daily review cap, reminder on/off and time, Japanese voice notice
- [ ] 11.8 ViewModel unit tests for home, lesson, review, kana detail and goal, using fakes and asserting on `uiState`

## 12. Verification

- [ ] 12.1 Widget test for navigation between home, lesson, review, kana grid and settings
- [ ] 12.2 Run `flutter analyze` and `flutter test`; fix all issues
- [ ] 12.3 Manual run on the Android phone in airplane mode: first launch, goal setup, a lesson, a review session, editing a mnemonic, app restart keeps progress
- [ ] 12.4 Manual check of the reminder notification and of behaviour when notification permission is refused
- [ ] 12.5 Build a release APK and confirm it installs and starts
