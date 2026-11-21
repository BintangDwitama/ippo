# Ippo (一歩)

A personal app for learning Japanese from zero, one step at a time. The first
stage is a kana trainer: lessons that introduce hiragana and katakana with
mnemonics and audio, spaced-repetition reviews, and a goal to keep pace.

Built with Flutter, Android first. Everything is stored on the device and
works offline.

The look is chosen in Settings > Appearance: Automatic (Daylight by day,
Night in dark mode), Daylight, Night or Paper. All themes share one layout.

Kana are read aloud by the phone's Japanese voice. Settings > Sound sets
the speaking speed (Normal, Slow or Very slow) and plays a sample.

## What it teaches

208 kana: for each script, the 46 basic kana, 25 voiced (が, ぱ) and 33
combination kana (きゃ). The path finishes one script before the next:
hiragana basics, voiced, combination, then the same for katakana. Lessons
introduce whole rows, up to six kana. Goals cover one stage of the path.

The seed file is the source of app-owned content. On every launch the app
adds missing kana and updates the reading, order and default mnemonic of
existing ones; it never changes the learner's progress or own mnemonics.

## Your data

Progress is stored only on the phone. Settings > Backup and restore saves
it as one JSON file (`ippo-backup-YYYY-MM-DD.json`) wherever you choose,
and brings such a file back. An import replaces everything on the phone
after showing what the file holds. Android's own backup also includes the
database when backup is turned on in the phone's settings.

A backup written by a newer version of the app cannot be imported by an
older one; the older app says it needs a newer version.

When developing: export before installing a build that may need the app
to be uninstalled first (for example one signed with a different key),
because an uninstall deletes the data.

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
  ui/backup/              export and import of the learner's data
  ui/core/theme/          design tokens and the Daylight, Night and Paper themes
  ui/core/widgets/        shared widgets; they read tokens, never a theme name
  domain/                 models, the scheduler, use cases
  data/                   repositories, services, seed loader
assets/seed/kana.json     the 208 kana with readings, groups, rows and mnemonics
assets/fonts/             bundled fonts (SIL Open Font License) and their licences
openspec/                 specs, design and tasks for each change
```

Project standards (layered architecture, naming, testing) are in
`openspec/config.yaml`.
