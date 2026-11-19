import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// A kana character drawn large in the textbook-style font.
class KanaText extends StatelessWidget {
  const KanaText(this.character, {super.key, this.size = 120, this.color});

  final String character;
  final double size;

  /// Defaults to the theme's text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      character,
      locale: const Locale('ja'),
      textAlign: TextAlign.center,
      // Already display-sized; scaling it further only causes clipping.
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: context.tokens.kanaFontFamily,
        fontSize: size,
        height: 1.15,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// A small square cell showing one kana, optionally with a caption.
class KanaTile extends StatelessWidget {
  const KanaTile({
    super.key,
    required this.character,
    required this.background,
    required this.foreground,
    this.caption,
    this.semanticLabel,
    this.onTap,
  });

  final String character;
  final Color background;
  final Color foreground;

  /// Shown under the character, for example its reading.
  final String? caption;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final caption = this.caption;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(tokens.smallRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KanaText(character, size: 28, color: foreground),
                    if (caption != null)
                      Text(
                        caption,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: foreground),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
