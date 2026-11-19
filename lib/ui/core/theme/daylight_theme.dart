import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';
import 'package:ippo/ui/core/theme/theme_builder.dart';

/// Daylight: light, soft and rounded, with one blue accent.
ThemeData buildDaylightTheme() {
  const page = Color(0xFFEEF2F9);
  const card = Color(0xFFFFFFFF);
  const ink = Color(0xFF141B2D);
  const inkMuted = Color(0xFF55607A);
  const blue = Color(0xFF2459E0);
  const blueDeep = Color(0xFF1A3FA6);
  const blueSoft = Color(0xFFE6EDFF);
  const line = Color(0xFFD8E1F2);
  const amberSoft = Color(0xFFFFE9D6);
  const amberDeep = Color(0xFF7A3A0A);

  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: blue,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: blueSoft,
    onPrimaryContainer: blueDeep,
    secondary: blueDeep,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: blueSoft,
    onSecondaryContainer: blueDeep,
    tertiary: amberDeep,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: amberSoft,
    onTertiaryContainer: amberDeep,
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDE7E4),
    onErrorContainer: Color(0xFF8C1D18),
    surface: card,
    onSurface: ink,
    onSurfaceVariant: inkMuted,
    surfaceContainerLowest: card,
    surfaceContainerLow: card,
    surfaceContainer: card,
    surfaceContainerHigh: card,
    surfaceContainerHighest: Color(0xFFE4E9F2),
    outline: Color(0xFF7A869F),
    outlineVariant: line,
    surfaceTint: Colors.transparent,
  );

  const tokens = IppoTokens(
    kanaFontFamily: kanaFontFamily,
    surfaceStyle: SurfaceStyle.filled,
    streakStyle: StreakStyle.pill,
    cardRadius: 28,
    controlRadius: 28,
    cardColor: card,
    cardBorder: line,
    heroBackground: blue,
    heroForeground: Color(0xFFFFFFFF),
    heroMuted: blueSoft,
    heroAction: Color(0xFFFFFFFF),
    onHeroAction: blueDeep,
    correct: Color(0xFFDDF3E4),
    onCorrect: Color(0xFF0F5132),
    wrong: Color(0xFFFDE7E4),
    onWrong: Color(0xFF8C1D18),
    streakBackground: amberSoft,
    streakForeground: amberDeep,
    progressTrack: Color(0xFFCFDAF0),
    progressFill: blue,
    tileNotStarted: Color(0xFFE4E9F2),
    onTileNotStarted: inkMuted,
    tileLearning: amberSoft,
    onTileLearning: amberDeep,
    tileKnown: blue,
    onTileKnown: Color(0xFFFFFFFF),
    choiceBackground: card,
    choiceForeground: ink,
    choiceBorder: line,
    noteBackground: blueSoft,
    noteForeground: ink,
  );

  return buildIppoTheme(
    scheme: scheme,
    pageColor: page,
    tokens: tokens,
    bodyFamily: 'Plus Jakarta Sans',
    headingFamily: 'Plus Jakarta Sans',
    headingWeight: FontWeight.w800,
  );
}
