## Context

The UI layer is about 2,700 lines in `lib/ui/`: seven screens, each with a ViewModel and an immutable `UiState`, plus `ui/core/` with a 33-line theme (`ColorScheme.fromSeed` on indigo) and five shared widgets. `main.dart` passes `AppTheme.light()` and `AppTheme.dark()` to `MaterialApp.router` and lets the system pick. Screens style themselves with `Theme.of(context)` and literal sizes.

Three directions were mocked up on a design canvas (https://claude.ai/artifact/E6y3rembFH9TArf5MX2WsQ, private to the author): A Paper and ink, B Night, C Soft daylight. The decision from exploration: ship all three as selectable themes, with one shared layout, a four-option Appearance setting, and one Japanese font for all themes. The mockups are the visual reference for colours and proportions; where a mockup's layout differs from the shared layout defined here, this document wins.

The project standards apply: data only through repositories, one ViewModel per screen with a single immutable `uiState`, constructor injection, fakes in tests.

## Goals / Non-Goals

**Goals:**
- A token system that makes a theme a data definition, so adding or adjusting a theme touches one file.
- Three themes that each look intentional, on one set of screens.
- A home screen with a clear single next action.
- The learner's theme choice persists, applies without restart, and shows no flash of the wrong theme at launch.
- Every theme meets text contrast requirements, checked by a test.

**Non-Goals:**
- Changing navigation structure, routes or any learning behaviour.
- Per-theme layouts, or learner-defined colours.
- Light and dark variants of each theme (six palettes).
- Illustrations, a mascot, a new launcher icon.
- Tablet or landscape layouts beyond not breaking.

## Decisions

### 1. A theme is `ThemeData` plus one `ThemeExtension` of app tokens

```dart
enum SurfaceStyle { filled, outlined }
enum StreakStyle { pill, seal }

class IppoTokens extends ThemeExtension<IppoTokens> {
  final String kanaFontFamily;
  final SurfaceStyle surfaceStyle;      // cards filled (Daylight, Night) or outlined (Paper)
  final StreakStyle streakStyle;
  final double cardRadius, controlRadius;
  final Color heroBackground, heroForeground, heroAction, onHeroAction;
  final Color correct, onCorrect, wrong, onWrong;
  final Color streakBackground, streakForeground;
  final Color progressTrack, progressFill;
  ...
}
```

Standard roles (background, surface, primary, text colours, text theme, button shapes) go in `ThemeData`/`ColorScheme`, so stock Material widgets follow the theme without extra work. Only what Material has no role for goes in `IppoTokens`.

`lib/ui/core/theme/` holds `ippo_tokens.dart`, one file per theme (`daylight_theme.dart`, `night_theme.dart`, `paper_theme.dart`), and `app_themes.dart` that maps an appearance mode to themes. `app_theme.dart` is removed; `Gaps` moves to `ui/core/spacing.dart`.

Rule: **no widget asks which theme is active.** Widgets read tokens. Where themes differ in form and not only colour (streak pill versus seal, filled versus outlined cards), the difference is an enum token handled inside one shared widget. This is what keeps "one layout" true as screens are added.

Alternatives considered: three hand-written `ThemeData` with widgets branching on a theme id (branches spread through every screen); a single `ColorScheme.fromSeed` per theme (cannot express Paper's outlined surfaces or the hero card, and generated palettes are what makes the app look generic today).

### 2. Appearance modes

```dart
enum AppearanceMode { automatic, daylight, night, paper }
```

| Mode | `theme` | `darkTheme` | `themeMode` |
|---|---|---|---|
| automatic | Daylight | Night | system |
| daylight | Daylight | Daylight | light |
| night | Night | Night | dark |
| paper | Paper | Paper | light |

`AppearanceMode` is a domain model. Default is `automatic`, which is what a learner who never opens settings gets, and matches today's behaviour of following the system.

Alternative considered: separate "theme" and "brightness" settings giving six combinations. Rejected: twice the palettes to design and check, and Night is already the dark counterpart of Daylight.

### 3. Storage and observation

`SettingsRepository` gains:

```dart
Stream<AppearanceMode> getAppearanceModeStream();
Future<AppearanceMode> getAppearanceMode();
Future<void> setAppearanceMode(AppearanceMode mode);
```

`DriftSettingsRepository` stores the enum name under the key `appearance_mode` in the existing `settings` table and implements the stream with a drift `watch` query. An unknown or missing value maps to `automatic`, so a future build that removes a theme does not crash on old data. `FakeSettingsRepository` gets the same members backed by a stream controller.

### 4. The app root observes appearance through an app-scoped ViewModel

`AppViewModel` (a `ChangeNotifier`, `ui/app/`) takes `SettingsRepository`, subscribes to `getAppearanceModeStream()`, and exposes `AppUiState { AppearanceMode appearanceMode }`. `IppoApp` listens to it and builds `MaterialApp.router` with the row from the table in decision 2. It is app-scoped because it holds shared state for the whole widget tree; this is the one exception to "one ViewModel per screen", and it owns no screen.

`main()` awaits `getAppearanceMode()` before `runApp` and passes it as the initial state, so the first frame already has the right theme. The settings screen changes the mode through `SettingsViewModel.setAppearanceMode`, which only writes to the repository; the app root reacts through the stream. Unidirectional, and the two ViewModels do not know about each other.

Alternative considered: `SettingsViewModel` notifying the root directly. Rejected: couples a screen ViewModel to app state and bypasses the repository as the source of truth.

### 5. Fonts are bundled assets; one Japanese font for all themes

| Use | Font | Themes |
|---|---|---|
| Kana and any Japanese text | Klee One (SemiBold) | all |
| Headings, numerals, body | Plus Jakarta Sans | Daylight |
| Headings and numerals | Space Grotesk | Night |
| Body | Inter | Night, Paper |
| Headings | Source Serif 4 | Paper |

All are under the SIL Open Font License. Files live in `assets/fonts/` with each licence text in `assets/fonts/licenses/`, and are registered with `LicenseRegistry` so they appear on the licences page.

Klee One is a textbook-style face: さ, き, り and そ appear as they are handwritten, which the system gothic font does not do. `KanaText` and every kana label take the family from `IppoTokens.kanaFontFamily`.

Bundled, not fetched, because the app is offline-first. One Japanese font, because a Japanese font with kanji is several megabytes and stage 1 needs kanji; three would multiply that. The font is bundled whole in this change, since subsetting to kana would have to be undone for stage 1. The APK size is measured before and after (task 2.4); if the growth is unacceptable, subsetting is the fallback.

Measured (tasks 1.2 and 2.4): the release APK was 60.6 MB before the fonts and 66.6 MB with them, an increase of 6.0 MB (about 10%), nearly all of it Klee One (8.9 MB on disk before compression). The full font stays; no subsetting.

The Paper mockup used a Japanese mincho face for English headings. That would be a second Japanese font, so Paper uses a Latin serif instead.

### 6. One layout: what the mockups converge to

Home, top to bottom, in every theme:

```
┌──────────────────────────────┐
│ 一歩                 [▦] [⚙] │  wordmark in the kana font; kana grid, settings
│                              │
│ ┌──────────────────────────┐ │
│ │ Today's step             │ │  HERO: the primary action
│ │ 12  cards to review      │ │  - cards due      → review
│ │ [      Start review    ] │ │  - none due, lesson available → lesson
│ └──────────────────────────┘ │  - neither        → rest state, next due time
│ ┌──────────────────────────┐ │
│ │ Next lesson   5 new kana │ │  SECONDARY: shown when reviews are primary
│ │ [た][ち][つ][て][と]      │ │  and a lesson is available
│ │ [      Start lesson    ] │ │
│ └──────────────────────────┘ │
│ ┌─────────────────┐ ┌──────┐ │
│ │ Hiragana 15/46  │ │ 3    │ │  goal summary (opens goal screen) and streak
│ │ ▓▓▓░░░░ 11 days │ │ days │ │
│ └─────────────────┘ └──────┘ │
└──────────────────────────────┘
```

The voice notice and the first-launch goal setup keep their place above the hero. Paper draws the same cards outlined and flat, and the streak as a tilted seal; Daylight and Night draw them filled, with the streak as a pill or tile.

Review and lesson questions: a slim header (close, progress bar, count), the prompt in a large central surface, answers at the bottom in the existing two-by-two grid or text field. Feedback keeps its own state from the ViewModel; it adds an icon and a label ("Correct", "Not quite") next to the colour, and the correct answer is always shown in text.

Motion is small and optional: a short scale-and-fade on the feedback surface and on progress changes, skipped when the platform asks for reduced motion (`MediaQuery.disableAnimations`).

### 7. Home state additions

`HomeUiState` gains `nextLessonKana` (the characters of the next batch, from the existing `GetNextLesson`) and a derived `primaryAction` getter (`review`, `lesson`, `rest`). The decision of which action is primary lives in the state class, not in the widget, so it is unit-tested without Flutter. No use case changes.

### 8. Shared widgets

`ui/core/widgets/` (split from the single `widgets.dart`): `KanaText`, `KanaTile`, `IppoCard` (reads `surfaceStyle` and `cardRadius`), `HeroCard`, `PrimaryButton`/`SecondaryButton` (thin wrappers over themed Material buttons, for consistent height), `StreakBadge` (reads `streakStyle`), `ProgressMeter`, `ChoiceGrid`, `AudioButton`, `MnemonicNote`, `FeedbackBanner`, `MessageView`. Screens compose these and hold no colour or font literals.

### 9. Testing

- **Repository**: appearance mode round-trips, defaults to automatic, unknown stored value maps to automatic, stream emits on change (in-memory drift).
- **ViewModels**: `AppViewModel` follows the stream; `SettingsViewModel` writes the mode; `HomeUiState.primaryAction` for the three cases.
- **Contrast**: a pure Dart test computes the WCAG contrast ratio for each theme's declared text-on-background pairs (scheme pairs and token pairs) and requires 4.5:1.
- **Layout**: a widget test pumps home, review question and kana grid under each theme at 360x640 and at text scale 1.3 and expects no overflow errors.
- **Switching**: a widget test changes the mode in settings and expects the app's theme to change without restart.
- **Navigation**: the existing test is updated for reworded text.
- No golden image tests: fonts render differently across machines, and the suite must stay stable on Windows.

### 10. Build order

Tokens and Daylight first, with every screen migrated, so the app is complete and better after that step. Night and Paper are then token definitions plus the two form variants. The setting comes after there is more than one theme to choose.

### 11. Notes from implementation

- The Latin fonts are variable fonts. Text styles set the weight both as `fontWeight` and as a `wght` font variation (`TextStyle.weighted`), so the weight is selected reliably.
- Every text style lists the kana font as a fallback, so Japanese inside an English sentence (for example the correct answer in feedback) is also drawn in the textbook-style font.
- The app only has a feedback state for wrong answers; a correct answer moves straight to the next card. `FeedbackBanner` supports both, but only the wrong-answer form is shown. Adding a correct-answer state would change review behaviour and is left out of this change.
- The debug banner is turned off, because it covered the settings button on the home screen.
- Screens keep a standard app bar with a back button; lessons and reviews put the progress bar and count in its title.

## Risks / Trade-offs

- **Paper loses some character under a shared layout** (the mockup had no cards and a divider) → Outlined flat cards, the seal and the serif headings carry it; check on the phone and adjust tokens, not layout.
- **Three themes weaken a single brand look** → The 一歩 wordmark in the kana font and the layout are constant across themes.
- **APK grows by several megabytes from the Japanese font** → Measured in task 2.4; kana-only subsetting is the fallback, with the note that stage 1 would need the full font back.
- **Klee One's thin strokes may read poorly at small sizes or on Night** → Use the SemiBold weight; check the kana grid on the device in each theme.
- **A token is missed and a screen keeps a hard-coded colour** → A grep task for `Color(0x` and `Colors.` outside `ui/core/theme/` before verification.
- **Reworded home text breaks the navigation test** → Updated in the same task group as the home screen.
- **Every future screen must be checked in three themes** → The layout widget test iterates themes, so new screens are added to one list.
- **The contrast test only covers declared pairs** → Keep text on a small set of surfaces; manual check on the device remains.

## Migration Plan

No data migration. A learner who updates has no `appearance_mode` key and gets Automatic, which follows the system as the app does today. Rollback is reverting the change; the extra settings key is ignored by the old code.

## Open Questions

- Whether Paper should later get a dark counterpart so Automatic can pair with it. Not in this change.
- Final accent values may shift slightly after seeing them on the phone; the mockup values are the starting point.
