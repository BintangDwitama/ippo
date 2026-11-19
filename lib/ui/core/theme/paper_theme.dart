import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';
import 'package:ippo/ui/core/theme/theme_builder.dart';

/// Paper: warm paper, ink, and one vermilion accent, like a seal on a
/// page. Surfaces are flat and outlined.
ThemeData buildPaperTheme() {
  const paper = Color(0xFFF6F1E7);
  const paperDeep = Color(0xFFEDE5D6);
  const ink = Color(0xFF1F1B16);
  const inkMuted = Color(0xFF5E564B);
  const vermilion = Color(0xFFB93227);
  const white = Color(0xFFFFFFFF);

  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: vermilion,
    onPrimary: white,
    primaryContainer: paperDeep,
    onPrimaryContainer: ink,
    secondary: ink,
    onSecondary: paper,
    secondaryContainer: paperDeep,
    onSecondaryContainer: ink,
    tertiary: vermilion,
    onTertiary: white,
    tertiaryContainer: Color(0xFFF1D9B8),
    onTertiaryContainer: Color(0xFF5A3A0A),
    error: Color(0xFF9C2A20),
    onError: white,
    errorContainer: Color(0xFFF3D9D4),
    onErrorContainer: Color(0xFF7A1F18),
    surface: paper,
    onSurface: ink,
    onSurfaceVariant: inkMuted,
    surfaceContainerLowest: paper,
    surfaceContainerLow: paper,
    surfaceContainer: paper,
    surfaceContainerHigh: paper,
    surfaceContainerHighest: paperDeep,
    outline: inkMuted,
    outlineVariant: Color(0xFFD9CFBD),
    surfaceTint: Colors.transparent,
  );

  const tokens = IppoTokens(
    kanaFontFamily: kanaFontFamily,
    surfaceStyle: SurfaceStyle.outlined,
    streakStyle: StreakStyle.seal,
    cardRadius: 4,
    controlRadius: 4,
    cardColor: paper,
    cardBorder: ink,
    heroBackground: paper,
    heroForeground: ink,
    heroMuted: Color(0xFF4A433A),
    heroAction: vermilion,
    onHeroAction: white,
    correct: Color(0xFFDCE8D6),
    onCorrect: Color(0xFF24482A),
    wrong: Color(0xFFF3D9D4),
    onWrong: Color(0xFF7A1F18),
    streakBackground: vermilion,
    streakForeground: white,
    progressTrack: Color(0xFFD9CFBD),
    progressFill: ink,
    tileNotStarted: paperDeep,
    onTileNotStarted: inkMuted,
    tileLearning: Color(0xFFF1D9B8),
    onTileLearning: Color(0xFF5A3A0A),
    tileKnown: ink,
    onTileKnown: paper,
    choiceBackground: paper,
    choiceForeground: ink,
    choiceBorder: ink,
    noteBackground: paperDeep,
    noteForeground: ink,
  );

  return buildIppoTheme(
    scheme: scheme,
    pageColor: paper,
    tokens: tokens,
    bodyFamily: 'Inter',
    headingFamily: 'Source Serif 4',
    headingWeight: FontWeight.w700,
  );
}
