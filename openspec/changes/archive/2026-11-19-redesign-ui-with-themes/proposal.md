## Why

The kana trainer works, but it looks like an unstyled template: a stock Material theme from one seed colour, a home screen of three equal cards, and kana drawn in the system font. The app is now meant for a wide audience, not only its author, so it has to be pleasant to look at before anyone is asked to use it daily, and different people want different looks.

## What Changes

- Replace the single seed-colour theme with a design token system (colours, type, shapes, surface style) that every screen and shared widget reads from.
- Ship three visual themes built on those tokens: **Daylight** (light, soft, rounded), **Night** (dark, high-contrast numerals) and **Paper** (warm paper, ink and one vermilion accent).
- Add an Appearance setting with four choices: Automatic (Daylight in light mode, Night in dark mode), Daylight, Night, Paper. The choice is stored on the device and applies immediately.
- All themes share one layout. A theme changes how things look, never where they are or what they say.
- Bundle a textbook-style Japanese font and use it for kana in every theme, so characters appear in their handwritten forms. Bundle the Latin fonts each theme needs. No font is fetched from the network.
- Rebuild the home screen around one primary action: reviews when cards are due, otherwise the next lesson. Show the next lesson as its actual kana, and goal progress and streak as a compact summary.
- Restyle the lesson, review, kana grid, kana detail, goal and settings screens with the tokens, including clear correct and wrong feedback that does not rely on colour alone.
- Navigation, routes, ViewModel logic, use cases and stored learning data are unchanged.

## Capabilities

### New Capabilities

- `appearance`: The selectable visual themes, the Appearance setting and its persistence, the rule that themes share one layout, the bundled kana font, and legibility requirements that hold in every theme.
- `home-screen`: What the home screen presents and in what priority: one primary action, the next-lesson preview, and the goal and streak summary.

### Modified Capabilities

None. Existing requirements for lessons, reviews, goals, kana content, scheduling and audio keep their behaviour; only their presentation changes.

## Impact

- **Code**: `lib/ui/` (theme, shared widgets and all seven screens), `lib/main.dart` (theme selection at the app root), `SettingsRepository` and its drift implementation (one new setting), `SettingsViewModel` and `SettingsUiState`, `HomeUiState` and `HomeViewModel` (next-lesson kana and primary action).
- **Assets**: new font files under `assets/fonts/`, declared in `pubspec.yaml`. The APK grows by the size of the fonts; the Japanese font is the large one.
- **Dependencies**: none added. Fonts are bundled as assets, not loaded with a font package.
- **Data**: one new key in the existing `settings` table. No schema change and no migration.
- **Tests**: the navigation widget test finds widgets by text that this change rewords, so it is updated. New tests cover the setting, theme switching, contrast of token pairs, and layout at small sizes and large text.
- **Licences**: the bundled fonts are under the SIL Open Font License; their licence files are added to the repository.
- **Out of scope**: navigation changes (bottom navigation, onboarding), learner-defined custom colours, illustrations or a mascot, a new app icon, tablet layouts, iOS builds.
