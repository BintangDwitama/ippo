# Ippo (一歩)

A personal app for learning Japanese from zero, one step at a time. The first
stage is a kana trainer: lessons that introduce hiragana and katakana with
mnemonics and audio, spaced-repetition reviews, and a goal to keep pace.

Built with Flutter, Android first. Everything is stored on the device and
works offline.

The look is chosen in Settings > Appearance: Automatic (Daylight by day,
Night in dark mode), Daylight, Night or Paper. All themes share one layout.

## Getting started

```
flutter pub get
dart run build_runner build
flutter run
```

`build_runner` generates the database code (`*.g.dart`), which is not checked
in. Run it again after changing `lib/data/services/app_database.dart`.

Install the Flutter SDK in a path without spaces. Some dependencies use
native build hooks that fail otherwise.

## Checks

```
flutter analyze
flutter test
```

## Structure

```
lib/
  main.dart               entry point and dependency wiring
  app_dependencies.dart   repositories and use cases, built once
  routing/                go_router routes
  ui/                     screens, one ViewModel and UiState per screen
  ui/core/theme/          design tokens and the Daylight, Night and Paper themes
  ui/core/widgets/        shared widgets; they read tokens, never a theme name
  domain/                 models, the scheduler, use cases
  data/                   repositories, services, seed loader
assets/seed/kana.json     the 92 kana with readings and mnemonics
assets/fonts/             bundled fonts (SIL Open Font License) and their licences
openspec/                 specs, design and tasks for each change
```

Project standards (layered architecture, naming, testing) are in
`openspec/config.yaml`.
