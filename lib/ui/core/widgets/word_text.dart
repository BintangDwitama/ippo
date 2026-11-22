import 'package:flutter/material.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// A word as the learner reads it: the reading in kana, large, with the
/// written form smaller beneath when the word has one.
///
/// The written form is there to be recognised, not read: it tells apart
/// words that share a reading.
class WordText extends StatelessWidget {
  const WordText(this.word, {super.key, this.size = 64, this.color});

  final WordPayload word;

  /// Font size of the reading; the written form is drawn at 45% of it.
  final double size;

  /// Defaults to the theme's text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final written = word.written;
    final color = this.color ?? theme.colorScheme.onSurface;
    TextStyle style(double fontSize, Color color) => TextStyle(
          fontFamily: context.tokens.kanaFontFamily,
          fontSize: fontSize,
          height: 1.2,
          color: color,
        );
    // Scaled down as one block when the space is narrower than the
    // reading, so a long word stays on one line.
    return Semantics(
      label: written == null ? word.reading : '${word.reading}, $written',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.reading,
              locale: const Locale('ja'),
              maxLines: 1,
              softWrap: false,
              // Already display-sized; scaling further only clips.
              textScaler: TextScaler.noScaling,
              style: style(size, color),
            ),
            if (written != null)
              Text(
                written,
                locale: const Locale('ja'),
                maxLines: 1,
                softWrap: false,
                textScaler: TextScaler.noScaling,
                style: style(
                  size * 0.45,
                  this.color ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A word on one line, for a list or an answer button: the reading, then
/// the written form smaller beside it.
class WordLine extends StatelessWidget {
  const WordLine(this.word, {super.key, this.size = 26, this.color});

  final WordPayload word;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final written = word.written;
    final color = this.color ?? DefaultTextStyle.of(context).style.color;
    final family = context.tokens.kanaFontFamily;
    return Semantics(
      label: written == null ? word.reading : '${word.reading}, $written',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            text: word.reading,
            children: [
              if (written != null)
                TextSpan(
                  text: '  $written',
                  style: TextStyle(
                    fontSize: size * 0.7,
                    color: color?.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
          locale: const Locale('ja'),
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontFamily: family, fontSize: size, color: color),
        ),
      ),
    );
  }
}
