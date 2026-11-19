import 'package:flutter/material.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/ui/core/theme/daylight_theme.dart';
import 'package:ippo/ui/core/theme/night_theme.dart';
import 'package:ippo/ui/core/theme/paper_theme.dart';

/// The themes `MaterialApp` needs for one [AppearanceMode].
typedef ThemeSelection = ({
  ThemeData theme,
  ThemeData darkTheme,
  ThemeMode themeMode,
});

/// The app's themes, built once.
abstract final class AppThemes {
  static final ThemeData daylight = buildDaylightTheme();
  static final ThemeData night = buildNightTheme();
  static final ThemeData paper = buildPaperTheme();

  /// Every theme by name, for tests that must hold in all of them.
  static Map<String, ThemeData> get all => {
    'Daylight': daylight,
    'Night': night,
    'Paper': paper,
  };

  static ThemeSelection forMode(AppearanceMode mode) {
    return switch (mode) {
      AppearanceMode.automatic => (
        theme: daylight,
        darkTheme: night,
        themeMode: ThemeMode.system,
      ),
      AppearanceMode.daylight => (
        theme: daylight,
        darkTheme: daylight,
        themeMode: ThemeMode.light,
      ),
      AppearanceMode.night => (
        theme: night,
        darkTheme: night,
        themeMode: ThemeMode.dark,
      ),
      AppearanceMode.paper => (
        theme: paper,
        darkTheme: paper,
        themeMode: ThemeMode.light,
      ),
    };
  }
}
