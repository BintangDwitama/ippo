## 1. Preparation

- [x] 1.1 Fix git access to the repository ("dubious ownership" error): with the owner's agreement, run `git config --global --add safe.directory C:/Users/binta/Documents/Project/Ippo`, then confirm `git status` works
- [x] 1.2 Run `flutter analyze` and `flutter test` to confirm a clean baseline; build a release APK and record its size in design.md

## 2. Fonts

- [x] 2.1 Download Klee One (SemiBold), Plus Jakarta Sans, Space Grotesk, Inter and Source Serif 4 from their official sources into `assets/fonts/`, with each OFL licence text in `assets/fonts/licenses/`
- [x] 2.2 Declare the font families in `pubspec.yaml` with the weights the themes use
- [x] 2.3 Register the font licences with `LicenseRegistry` at startup
- [x] 2.4 Build a release APK, record the size increase in design.md, and decide whether the full Japanese font stays or is subset to kana

## 3. Token system and Daylight theme

- [x] 3.1 Create `lib/ui/core/theme/ippo_tokens.dart`: `IppoTokens` as a `ThemeExtension` with `copyWith` and `lerp`, and the `SurfaceStyle` and `StreakStyle` enums
- [x] 3.2 Create `daylight_theme.dart`: `ColorScheme`, text theme, button, card and input themes, and its `IppoTokens`, using the canvas mockup C values
- [x] 3.3 Move `Gaps` to `lib/ui/core/spacing.dart` and remove `app_theme.dart`; point `main.dart` at Daylight for now
- [x] 3.4 Add a pure Dart WCAG contrast helper and a test that every declared text and surface pair of Daylight reaches 4.5:1

## 4. Shared widgets

- [x] 4.1 Split `ui/core/widgets.dart` into `ui/core/widgets/`, one file per widget, keeping `formatTimeUntil`
- [x] 4.2 Rework `KanaText` to use `kanaFontFamily`, and add `KanaTile` for small kana cells
- [x] 4.3 Add `IppoCard` and `HeroCard` (reading `surfaceStyle`, `cardRadius` and the hero colours)
- [x] 4.4 Add `PrimaryButton`, `SecondaryButton`, `ProgressMeter` and `StreakBadge` (reading `streakStyle`)
- [x] 4.5 Rework `ChoiceGrid`, `AudioButton`, `MnemonicNote` and `MessageView` to read tokens, with tap targets of at least 44 logical pixels
- [x] 4.6 Add `FeedbackBanner`: icon, text label and colour for correct and wrong, with a short animation skipped when `MediaQuery.disableAnimations` is set

## 5. Home screen

- [x] 5.1 Add `nextLessonKana` and the derived `primaryAction` (review, lesson, rest) to `HomeUiState`; fill `nextLessonKana` in `HomeViewModel` from `GetNextLesson`
- [x] 5.2 Unit tests for `primaryAction` (cards due, lesson only, nothing to do, cap reached) and for `nextLessonKana` in `HomeViewModel`
- [x] 5.3 Rebuild `HomeScreen` to the shared layout: wordmark header, hero card, next-lesson card with kana tiles, goal summary and streak badge; keep the voice notice and first-launch goal setup
- [x] 5.4 Update `test/ui/navigation_test.dart` for the reworded home text

## 6. Remaining screens

- [x] 6.1 Restyle the review screen: slim header with close, progress and count; prompt surface; `FeedbackBanner` showing the correct answer in text; summary state
- [x] 6.2 Restyle the lesson screen: presenting, quiz, feedback and complete states with the same header and prompt surface
- [x] 6.3 Restyle the kana grid and kana detail screens: `KanaTile` per status, script switch, mnemonic note and edit controls
- [x] 6.4 Restyle the goal screen and the settings screen
- [x] 6.5 Search `lib/ui/` outside `core/theme/` for `Color(0x`, `Colors.` and literal `fontFamily` and replace each with theme or token values
- [x] 6.6 Run `flutter analyze` and `flutter test`; fix all issues

## 7. Night and Paper themes

- [x] 7.1 Create `night_theme.dart` from canvas mockup B (filled surfaces, pill streak)
- [x] 7.2 Create `paper_theme.dart` from canvas mockup A (outlined flat surfaces, seal streak, serif headings)
- [x] 7.3 Extend the contrast test to Night and Paper and adjust colours until every pair passes
- [x] 7.4 Add `app_themes.dart` listing all themes for tests and for the mode mapping

## 8. Appearance setting

- [x] 8.1 Add the `AppearanceMode` domain model (automatic, daylight, night, paper)
- [x] 8.2 Add `getAppearanceModeStream`, `getAppearanceMode` and `setAppearanceMode` to `SettingsRepository`; implement in `DriftSettingsRepository` under the key `appearance_mode`, mapping missing or unknown values to automatic; update `FakeSettingsRepository`
- [x] 8.3 Repository tests: default, round trip, unknown value, stream emits on change
- [x] 8.4 Add `AppViewModel` and `AppUiState` in `lib/ui/app/`, observing the stream, with unit tests
- [x] 8.5 In `main.dart`, read the stored mode before `runApp`, create `AppViewModel` with it, and build `MaterialApp.router` with `theme`, `darkTheme` and `themeMode` from the mode table in design.md
- [x] 8.6 Add `appearanceMode` to `SettingsUiState` and `setAppearanceMode` to `SettingsViewModel`, with unit tests
- [x] 8.7 Add the Appearance choice with four options to the settings screen

## 9. Verification

- [x] 9.1 Widget test: selecting a mode in settings changes the app's theme without restart
- [x] 9.2 Widget test: home, a review question and the kana grid show no overflow in each theme at 360 by 640 logical pixels and at text scale 1.3
- [x] 9.3 Widget test: the home screen shows the same texts and buttons in all three themes
- [x] 9.4 Run `flutter analyze` and `flutter test`; fix all issues
- [x] 9.5 Manual run on the Android phone, in each theme: first launch, goal setup, a lesson, a review session with a wrong answer, kana grid and detail, settings; check kana legibility at grid size
- [x] 9.6 Manual check: Automatic follows the phone's dark mode switch; the chosen theme survives an app restart with no flash; feedback appears without animation when animations are turned off
- [x] 9.7 Build a release APK and confirm it installs and starts
