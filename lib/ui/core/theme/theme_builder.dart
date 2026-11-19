import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// The font shared by every theme for kana and other Japanese text.
const String kanaFontFamily = 'Klee One';

/// Builds a complete theme from a colour scheme, the app tokens and the
/// theme's fonts, so each theme file only states its values.
ThemeData buildIppoTheme({
  required ColorScheme scheme,
  required Color pageColor,
  required IppoTokens tokens,
  required String bodyFamily,
  required String headingFamily,
  required FontWeight headingWeight,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: pageColor,
    fontFamily: bodyFamily,
    // Japanese inside running text also uses the kana font.
    fontFamilyFallback: const [kanaFontFamily],
  );
  final textTheme = _textTheme(
    base.textTheme,
    bodyFamily: bodyFamily,
    headingFamily: headingFamily,
    headingWeight: headingWeight,
  );
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(tokens.controlRadius),
  );
  final buttonText = textTheme.titleMedium!.copyWith(fontSize: 17);
  final outlined = tokens.surfaceStyle == SurfaceStyle.outlined;

  return base.copyWith(
    textTheme: textTheme,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: pageColor,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: controlShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: controlShape,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: tokens.cardBorder, width: 1.5),
        textStyle: buttonText.copyWith(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.smallRadius),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: outlined
            ? BorderSide(color: tokens.cardBorder, width: 1.5)
            : BorderSide.none,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.progressFill,
      linearTrackColor: tokens.progressTrack,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

TextTheme _textTheme(
  TextTheme base, {
  required String bodyFamily,
  required String headingFamily,
  required FontWeight headingWeight,
}) {
  const fallback = [kanaFontFamily];
  TextStyle heading(TextStyle? style) => style!
      .copyWith(fontFamily: headingFamily, fontFamilyFallback: fallback)
      .weighted(headingWeight);
  TextStyle body(TextStyle? style, FontWeight weight) => style!
      .copyWith(fontFamily: bodyFamily, fontFamilyFallback: fallback)
      .weighted(weight);

  return base.copyWith(
    displayLarge: heading(base.displayLarge),
    displayMedium: heading(base.displayMedium),
    displaySmall: heading(base.displaySmall),
    headlineLarge: heading(base.headlineLarge),
    headlineMedium: heading(base.headlineMedium),
    headlineSmall: heading(base.headlineSmall),
    titleLarge: heading(base.titleLarge),
    titleMedium: heading(base.titleMedium),
    titleSmall: heading(base.titleSmall),
    bodyLarge: body(base.bodyLarge, FontWeight.w400),
    bodyMedium: body(base.bodyMedium, FontWeight.w400),
    bodySmall: body(base.bodySmall, FontWeight.w400),
    labelLarge: body(base.labelLarge, FontWeight.w600),
    labelMedium: body(base.labelMedium, FontWeight.w600),
    labelSmall: body(base.labelSmall, FontWeight.w600),
  );
}
