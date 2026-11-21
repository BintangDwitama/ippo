import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/contrast.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// Every combination of text colour and surface the screens use in
/// [theme]. Each must stay readable; a test checks them all.
List<ContrastPair> textContrastPairs(ThemeData theme) {
  final scheme = theme.colorScheme;
  final tokens = theme.extension<IppoTokens>()!;
  final page = theme.scaffoldBackgroundColor;
  return [
    ContrastPair('text on page', scheme.onSurface, page),
    ContrastPair('muted text on page', scheme.onSurfaceVariant, page),
    ContrastPair('accent text on page', scheme.primary, page),
    ContrastPair('error text on page', scheme.error, page),
    ContrastPair('text on card', scheme.onSurface, tokens.cardColor),
    ContrastPair(
      'muted text on card',
      scheme.onSurfaceVariant,
      tokens.cardColor,
    ),
    ContrastPair('accent text on card', scheme.primary, tokens.cardColor),
    ContrastPair('primary button', scheme.onPrimary, scheme.primary),
    ContrastPair('destructive button', scheme.onError, scheme.error),
    ContrastPair(
      'tonal button',
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
    ),
    ContrastPair('hero text', tokens.heroForeground, tokens.heroBackground),
    ContrastPair('hero muted text', tokens.heroMuted, tokens.heroBackground),
    ContrastPair('hero button', tokens.onHeroAction, tokens.heroAction),
    ContrastPair('correct feedback', tokens.onCorrect, tokens.correct),
    ContrastPair('wrong feedback', tokens.onWrong, tokens.wrong),
    ContrastPair('streak', tokens.streakForeground, tokens.streakBackground),
    ContrastPair(
      'tile, not started',
      tokens.onTileNotStarted,
      tokens.tileNotStarted,
    ),
    ContrastPair('tile, learning', tokens.onTileLearning, tokens.tileLearning),
    ContrastPair('tile, known', tokens.onTileKnown, tokens.tileKnown),
    ContrastPair(
      'answer button',
      tokens.choiceForeground,
      tokens.choiceBackground,
    ),
    ContrastPair('mnemonic note', tokens.noteForeground, tokens.noteBackground),
  ];
}
