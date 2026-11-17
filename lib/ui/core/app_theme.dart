import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF3F51B5);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Spacing used across screens.
abstract final class Gaps {
  static const double page = 16;
  static const SizedBox small = SizedBox(height: 8, width: 8);
  static const SizedBox medium = SizedBox(height: 16, width: 16);
  static const SizedBox large = SizedBox(height: 32, width: 32);
}
