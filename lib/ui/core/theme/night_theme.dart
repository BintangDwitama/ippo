import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';
import 'package:ippo/ui/core/theme/theme_builder.dart';

/// Night: dark surfaces, large numerals, an orange action colour and blue
/// for progress.
ThemeData buildNightTheme() {
  const page = Color(0xFF0F1218);
  const card = Color(0xFF181C25);
  const raised = Color(0xFF222835);
  const line = Color(0xFF323A4A);
  const ink = Color(0xFFF2F4F8);
  const inkMuted = Color(0xFF9AA3B2);
  const orange = Color(0xFFFF8A3D);
  const onOrange = Color(0xFF14100B);
  const orangeDim = Color(0xFF2A1D12);
  const blue = Color(0xFF6EA8FF);

  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: orange,
    onPrimary: onOrange,
    primaryContainer: orangeDim,
    onPrimaryContainer: orange,
    secondary: blue,
    onSecondary: page,
    secondaryContainer: raised,
    onSecondaryContainer: ink,
    tertiary: orange,
    onTertiary: onOrange,
    tertiaryContainer: orangeDim,
    onTertiaryContainer: orange,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF3A1A1A),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: card,
    onSurface: ink,
    onSurfaceVariant: inkMuted,
    surfaceContainerLowest: page,
    surfaceContainerLow: card,
    surfaceContainer: card,
    surfaceContainerHigh: card,
    surfaceContainerHighest: raised,
    outline: Color(0xFF6B7588),
    outlineVariant: line,
    surfaceTint: Colors.transparent,
  );

  const tokens = IppoTokens(
    kanaFontFamily: kanaFontFamily,
    surfaceStyle: SurfaceStyle.filled,
    streakStyle: StreakStyle.pill,
    cardRadius: 24,
    controlRadius: 16,
    cardColor: card,
    cardBorder: line,
    heroBackground: card,
    heroForeground: ink,
    heroMuted: Color(0xFFC9D0DC),
    heroAction: orange,
    onHeroAction: onOrange,
    correct: Color(0xFF12301F),
    onCorrect: Color(0xFF8FE3B0),
    wrong: Color(0xFF3A1A1A),
    onWrong: Color(0xFFFFB4AB),
    streakBackground: orangeDim,
    streakForeground: orange,
    progressTrack: Color(0xFF262C39),
    progressFill: blue,
    tileNotStarted: raised,
    onTileNotStarted: inkMuted,
    tileLearning: orangeDim,
    onTileLearning: orange,
    tileKnown: blue,
    onTileKnown: page,
    choiceBackground: raised,
    choiceForeground: ink,
    choiceBorder: line,
    noteBackground: raised,
    noteForeground: ink,
  );

  return buildIppoTheme(
    scheme: scheme,
    pageColor: page,
    tokens: tokens,
    bodyFamily: 'Inter',
    headingFamily: 'Space Grotesk',
    headingWeight: FontWeight.w700,
  );
}
