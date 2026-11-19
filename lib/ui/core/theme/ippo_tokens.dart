import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// How cards and other surfaces are drawn.
enum SurfaceStyle {
  /// A solid fill that stands out from the page.
  filled,

  /// The page colour with a drawn border.
  outlined,
}

/// How the streak is drawn.
enum StreakStyle {
  /// A soft tile with a flame.
  pill,

  /// A tilted stamp, like a seal pressed on paper.
  seal,
}

/// The visual values a theme defines beyond Material's own colour roles.
///
/// Widgets read these and never ask which theme is active, so a new theme
/// is only a new set of values.
@immutable
class IppoTokens extends ThemeExtension<IppoTokens> {
  const IppoTokens({
    required this.kanaFontFamily,
    required this.surfaceStyle,
    required this.streakStyle,
    required this.cardRadius,
    required this.controlRadius,
    required this.cardColor,
    required this.cardBorder,
    required this.heroBackground,
    required this.heroForeground,
    required this.heroMuted,
    required this.heroAction,
    required this.onHeroAction,
    required this.correct,
    required this.onCorrect,
    required this.wrong,
    required this.onWrong,
    required this.streakBackground,
    required this.streakForeground,
    required this.progressTrack,
    required this.progressFill,
    required this.tileNotStarted,
    required this.onTileNotStarted,
    required this.tileLearning,
    required this.onTileLearning,
    required this.tileKnown,
    required this.onTileKnown,
    required this.choiceBackground,
    required this.choiceForeground,
    required this.choiceBorder,
    required this.noteBackground,
    required this.noteForeground,
  });

  /// The font for kana and any other Japanese text.
  final String kanaFontFamily;
  final SurfaceStyle surfaceStyle;
  final StreakStyle streakStyle;

  final double cardRadius;
  final double controlRadius;

  final Color cardColor;

  /// The border of a card; only drawn when [surfaceStyle] is outlined.
  final Color cardBorder;

  /// The card holding the screen's primary action.
  final Color heroBackground;
  final Color heroForeground;

  /// Secondary text on the hero card.
  final Color heroMuted;
  final Color heroAction;
  final Color onHeroAction;

  /// Feedback after an answer.
  final Color correct;
  final Color onCorrect;
  final Color wrong;
  final Color onWrong;

  final Color streakBackground;
  final Color streakForeground;

  final Color progressTrack;
  final Color progressFill;

  /// Kana tiles by learning status.
  final Color tileNotStarted;
  final Color onTileNotStarted;
  final Color tileLearning;
  final Color onTileLearning;
  final Color tileKnown;
  final Color onTileKnown;

  /// Answer buttons.
  final Color choiceBackground;
  final Color choiceForeground;
  final Color choiceBorder;

  /// The mnemonic note.
  final Color noteBackground;
  final Color noteForeground;

  /// The radius for small elements such as tiles and notes, which look
  /// wrong with a very large card radius.
  double get smallRadius => cardRadius < 16 ? cardRadius : 16;

  @override
  IppoTokens copyWith({
    String? kanaFontFamily,
    SurfaceStyle? surfaceStyle,
    StreakStyle? streakStyle,
    double? cardRadius,
    double? controlRadius,
    Color? cardColor,
    Color? cardBorder,
    Color? heroBackground,
    Color? heroForeground,
    Color? heroMuted,
    Color? heroAction,
    Color? onHeroAction,
    Color? correct,
    Color? onCorrect,
    Color? wrong,
    Color? onWrong,
    Color? streakBackground,
    Color? streakForeground,
    Color? progressTrack,
    Color? progressFill,
    Color? tileNotStarted,
    Color? onTileNotStarted,
    Color? tileLearning,
    Color? onTileLearning,
    Color? tileKnown,
    Color? onTileKnown,
    Color? choiceBackground,
    Color? choiceForeground,
    Color? choiceBorder,
    Color? noteBackground,
    Color? noteForeground,
  }) {
    return IppoTokens(
      kanaFontFamily: kanaFontFamily ?? this.kanaFontFamily,
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      streakStyle: streakStyle ?? this.streakStyle,
      cardRadius: cardRadius ?? this.cardRadius,
      controlRadius: controlRadius ?? this.controlRadius,
      cardColor: cardColor ?? this.cardColor,
      cardBorder: cardBorder ?? this.cardBorder,
      heroBackground: heroBackground ?? this.heroBackground,
      heroForeground: heroForeground ?? this.heroForeground,
      heroMuted: heroMuted ?? this.heroMuted,
      heroAction: heroAction ?? this.heroAction,
      onHeroAction: onHeroAction ?? this.onHeroAction,
      correct: correct ?? this.correct,
      onCorrect: onCorrect ?? this.onCorrect,
      wrong: wrong ?? this.wrong,
      onWrong: onWrong ?? this.onWrong,
      streakBackground: streakBackground ?? this.streakBackground,
      streakForeground: streakForeground ?? this.streakForeground,
      progressTrack: progressTrack ?? this.progressTrack,
      progressFill: progressFill ?? this.progressFill,
      tileNotStarted: tileNotStarted ?? this.tileNotStarted,
      onTileNotStarted: onTileNotStarted ?? this.onTileNotStarted,
      tileLearning: tileLearning ?? this.tileLearning,
      onTileLearning: onTileLearning ?? this.onTileLearning,
      tileKnown: tileKnown ?? this.tileKnown,
      onTileKnown: onTileKnown ?? this.onTileKnown,
      choiceBackground: choiceBackground ?? this.choiceBackground,
      choiceForeground: choiceForeground ?? this.choiceForeground,
      choiceBorder: choiceBorder ?? this.choiceBorder,
      noteBackground: noteBackground ?? this.noteBackground,
      noteForeground: noteForeground ?? this.noteForeground,
    );
  }

  @override
  IppoTokens lerp(ThemeExtension<IppoTokens>? other, double t) {
    if (other is! IppoTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    final useOther = t >= 0.5;
    return IppoTokens(
      kanaFontFamily: useOther ? other.kanaFontFamily : kanaFontFamily,
      surfaceStyle: useOther ? other.surfaceStyle : surfaceStyle,
      streakStyle: useOther ? other.streakStyle : streakStyle,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      cardColor: c(cardColor, other.cardColor),
      cardBorder: c(cardBorder, other.cardBorder),
      heroBackground: c(heroBackground, other.heroBackground),
      heroForeground: c(heroForeground, other.heroForeground),
      heroMuted: c(heroMuted, other.heroMuted),
      heroAction: c(heroAction, other.heroAction),
      onHeroAction: c(onHeroAction, other.onHeroAction),
      correct: c(correct, other.correct),
      onCorrect: c(onCorrect, other.onCorrect),
      wrong: c(wrong, other.wrong),
      onWrong: c(onWrong, other.onWrong),
      streakBackground: c(streakBackground, other.streakBackground),
      streakForeground: c(streakForeground, other.streakForeground),
      progressTrack: c(progressTrack, other.progressTrack),
      progressFill: c(progressFill, other.progressFill),
      tileNotStarted: c(tileNotStarted, other.tileNotStarted),
      onTileNotStarted: c(onTileNotStarted, other.onTileNotStarted),
      tileLearning: c(tileLearning, other.tileLearning),
      onTileLearning: c(onTileLearning, other.onTileLearning),
      tileKnown: c(tileKnown, other.tileKnown),
      onTileKnown: c(onTileKnown, other.onTileKnown),
      choiceBackground: c(choiceBackground, other.choiceBackground),
      choiceForeground: c(choiceForeground, other.choiceForeground),
      choiceBorder: c(choiceBorder, other.choiceBorder),
      noteBackground: c(noteBackground, other.noteBackground),
      noteForeground: c(noteForeground, other.noteForeground),
    );
  }
}

extension IppoThemeContext on BuildContext {
  /// The current theme's app tokens.
  IppoTokens get tokens => Theme.of(this).extension<IppoTokens>()!;
}

extension IppoTextStyle on TextStyle {
  /// This style at [weight].
  ///
  /// The bundled Latin fonts are variable fonts, so the weight is also set
  /// as a font variation; `fontWeight` alone may not select it.
  TextStyle weighted(FontWeight weight) {
    return copyWith(
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );
  }
}
