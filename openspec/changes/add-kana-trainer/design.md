## Context

The repository contains only OpenSpec configuration; there is no application code. This change creates the Flutter app and its first feature, a kana trainer. Flutter 3.44 with Dart 3.12 is installed on the development machine (Windows); the target device is the learner's Android phone.

The project standards in `openspec/config.yaml` apply: SOLID, a layered architecture (UI, domain, data), repositories over every data source, one ViewModel per screen exposing a single immutable `uiState`, constructor injection, and fakes in tests.

Later stages (vocabulary, kanji, an AI partner that reads the review database) will reuse what is built here, so the card model and scheduler must not be kana-specific.

## Goals / Non-Goals

**Goals:**
- A usable kana trainer on Android, fully offline.
- A card model and scheduler that vocabulary and kanji can reuse unchanged.
- The layered structure and conventions established in a form later changes can copy.
- Core logic (scheduler, session building, quota, answer checking) covered by unit tests with no Flutter dependency.

**Non-Goals:**
- Voiced and combination kana (dakuten, handakuten, yōon). A follow-up change adds them as content only.
- Vocabulary, kanji, the AI partner, speech recognition, handwriting.
- Accounts, sync, backup or export.
- Building or testing on iOS.
- Tuning FSRS parameters to the learner's history.

## Decisions

### 0. Name: Ippo

The app is called Ippo (一歩, "one step"). The Flutter package and the GitHub repository are both `ippo`; the Android application id is `com.bintangdwitama.ippo`. The name deliberately does not mention kana, because later stages add vocabulary, kanji and the AI partner.

### 1. Project layout: feature folders inside three layers

```
lib/
  main.dart                 app entry, provider wiring
  routing/                  go_router configuration
  ui/
    core/                   theme, shared widgets
    home/  lesson/  review/  kana_grid/  goal/  settings/
      <feature>_screen.dart
      <feature>_view_model.dart
      <feature>_ui_state.dart
  domain/
    models/                 Item, Card, ReviewRecord, Goal, Rating ...
    scheduling/             Scheduler interface, FsrsScheduler
    use_cases/              BuildReviewSession, GradeAnswer, CompleteLesson,
                            CalculateDailyQuota, CheckTypedAnswer ...
  data/
    repositories/           interfaces + Default*/Drift* implementations
    services/               AppDatabase (drift), TtsService, NotificationService
    seed/                   kana seed loader
assets/seed/kana.json
test/                       mirrors lib/, with fakes in test/fakes/
```

This follows Flutter's official architecture guide, which matches the project standards. Alternative considered: a feature-first layout with all three layers inside each feature. Rejected because the scheduler, card model and repositories are shared by every feature, so most code would land in a "shared" feature anyway.

### 2. ViewModels are `ChangeNotifier`s exposing one immutable `uiState`

Each screen has a ViewModel extending `ChangeNotifier` with a single `uiState` getter of type `{Screen}UiState`. State classes are immutable; mutually exclusive states (loading, question, feedback, summary) use Dart sealed classes. Screens listen with `ListenableBuilder`. ViewModels take repositories and use cases through their constructor and never hold a `BuildContext`.

One-off effects are modelled as state. For example, "play this sound" is done by the ViewModel calling `SpeechRepository` directly, not by sending an event to the widget.

Alternative considered: Riverpod. Rejected for this project because it moves away from the ViewModel-per-screen pattern in the standards and adds concepts without a need at this size.

### 3. Dependency wiring with `provider`, constructor injection throughout

`main.dart` builds the object graph once: services, then repositories, then use cases, exposed with `Provider`. ViewModels are created in the route builder with `ChangeNotifierProvider`, so their lifetime is the screen's. Only the database, text-to-speech service and notification service are app-scoped, because they are expensive or hold shared state.

### 4. Storage: SQLite through `drift`

`drift` gives typed queries, migrations, and `Stream` queries, which map directly to the `get{Model}Stream` convention. Drift row classes stay inside the data layer; repositories map them to domain models.

Alternatives considered: `sqflite` (raw SQL strings, no streams, more hand-written mapping); `isar` or `hive` (non-relational, and review history with joins is naturally relational).

### 5. Generic data model

```
items            id, kind ('kana'), key ('hiragana:ka'), payload (JSON),
                 sort_order, introduced_at (nullable)
mnemonics        item_id, default_text, learner_text (nullable)
cards            id, item_id, prompt_type, state, due, stability, difficulty,
                 reps, lapses, consecutive_correct, last_review, created_at
review_records   id, card_id, reviewed_at, rating, was_correct,
                 state_before, elapsed_days
goals            id, target_set, target_accuracy, created_at, deadline, status
settings         key, value   (review cap, reminder time, voice notice shown)
```

`items.kind` and the JSON `payload` are what make the model generic: a vocabulary word or kanji later is a new `kind` with its own payload and prompt types, and `cards` and `review_records` are untouched. The kana payload holds character, script, romaji and accepted alternative romanisations.

`cards` is unique on `(item_id, prompt_type)`. `consecutive_correct` lives on the card because graduation is a property of one card's history and is read on every review.

Alternative considered: a dedicated `kana` table with scheduling columns. Rejected because stage 1 would need a rewrite of the scheduler's storage.

### 6. Scheduling: FSRS behind a `Scheduler` interface

```dart
abstract interface class Scheduler {
  SchedulingState initialState(DateTime now);
  SchedulingState next(SchedulingState current, Rating rating, DateTime now);
}
```

`FsrsScheduler` wraps the open-source Dart `fsrs` package with default parameters and 90% target retention. The interface uses only our own domain types, so the package is confined to one file. Time is always passed in, never read from the clock inside domain code, which keeps tests deterministic.

Grading is automatic: correct maps to `good`, wrong maps to `again`. The four-button self-rating of Anki is unnecessary for kana, where an answer is plainly right or wrong, and it removes a decision from every card.

Alternative considered: SM-2. It is simpler but schedules more reviews for the same retention. It remains the fallback: if the `fsrs` package proves unsuitable, an `Sm2Scheduler` implementing the same interface replaces it with no other change.

### 7. Session building is a pure use case

`BuildReviewSession` takes the due cards, the remaining cap, whether a Japanese voice is available, and a random source, and returns an ordered list:

1. Drop sound-to-character cards if no voice is available.
2. Take the most overdue cards up to the cap.
3. Shuffle, then repair the order so that no two consecutive cards share an item, where possible.

A card answered wrongly is reinserted at least three positions later (or at the end). Shuffling across the whole set gives interleaving of scripts and prompt types without separate rules for each. The random source is injected so tests can fix the seed.

### 8. Lessons and graduation

`CompleteLesson` runs in one database transaction: it sets `introduced_at` on each kana and creates two cards per kana, character-to-sound multiple choice and sound-to-character multiple choice. Because nothing is written until completion, abandoning a lesson needs no cleanup.

`GradeAnswer` updates the card through the scheduler, writes the review record, updates `consecutive_correct`, and when a character-to-sound multiple-choice card reaches three, creates the typed card. All in one transaction.

### 9. Multiple-choice distractors

Three wrong options are drawn from the same script, preferring introduced kana, and filled from not-yet-introduced kana when fewer than three are available (which happens in the first lesson). Options are drawn at presentation time, not stored, so they vary between reviews.

### 10. Seed content and mnemonics

`assets/seed/kana.json` holds the 92 kana with romaji, accepted alternatives, order and a default mnemonic. A seed loader inserts them on first launch inside a transaction, guarded by the unique `items.key`, so re-running is harmless.

The mnemonics are written for this project. Published kana mnemonic sets are copyrighted and are not copied. Learner edits go into `mnemonics.learner_text`, so a later change to the seed file never overwrites them.

### 11. Audio: `flutter_tts` behind `SpeechRepository`

```dart
abstract interface class SpeechRepository {
  Future<bool> isJapaneseVoiceAvailable();
  Future<void> speak(String text);
  Future<void> stop();
}
```

`TtsSpeechRepository` uses the device's `ja-JP` voice. The interface exists so that bundled recordings can replace it if the voice is poor for single syllables (see Risks).

### 12. Goals, quota and reminder

`CalculateDailyQuota` is a pure function of kana remaining, days remaining and kana introduced today. The streak is derived from review records and lesson dates, not stored, so it cannot drift out of step. Accuracy for the goal is the share of first-attempt correct answers over the goal's kana in the last 7 days.

The reminder uses `flutter_local_notifications` with a daily repeating schedule, behind a `ReminderRepository`. The Android 13+ notification permission is requested only when the learner turns the reminder on.

### 13. Testing approach

- Domain: unit tests for the scheduler wrapper, session building, quota, answer checking, graduation. Pure Dart.
- Data: repository tests against an in-memory drift database.
- UI: ViewModel unit tests using fake repositories (`FakeCardRepository`, `FakeSpeechRepository`, and so on) asserting on `uiState`; a widget test covering navigation between the main screens.
- No mocking library.

## Risks / Trade-offs

- **Device text-to-speech may pronounce single kana poorly** (clipped, or reading は as "wa") → Test on the learner's phone as an early task, before building the screens that depend on audio. If it is unacceptable, switch to bundled recordings behind the same `SpeechRepository`.
- **The Dart `fsrs` package may be unmaintained or differ from the reference algorithm** → Check it as an early task. It is isolated behind `Scheduler`; SM-2 is the fallback.
- **Auto-grading loses the "hard" and "easy" signals FSRS can use** → Accepted for kana. The `Rating` type keeps all four values, so a later change can add them for other card kinds.
- **Multiple choice lets the learner guess (25%)** → Graduation to typed answers after three correct reviews limits how long guessing can pass for knowledge.
- **A generic `payload` JSON column is not checked by the database** → Parsing is confined to one mapper per item kind in the data layer, with tests.
- **Local-only storage: uninstalling or losing the phone loses all progress** → Accepted for this change; export or backup is a candidate for the next one.
- **Scheduled notifications are unreliable on some Android phones with aggressive battery saving** → The reminder is a convenience; the home screen always shows what is due.
- **A 14-day goal for 46 hiragana may be too fast or too slow for this learner** → The goal is adjustable, and the quota recalculates daily.

## Migration Plan

Not applicable: this is a new app with no existing data. The drift schema starts at version 1 with migrations enabled, so later changes can add tables without data loss.

## Open Questions

- Whether は, へ and を should teach their particle pronunciations ("wa", "e", "o") now or when grammar is introduced. This design teaches the basic readings ("ha", "he", "wo") only.
