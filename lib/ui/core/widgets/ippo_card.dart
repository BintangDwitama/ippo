import 'package:flutter/material.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// A surface grouping related content, drawn filled or outlined as the
/// theme asks.
class IppoCard extends StatelessWidget {
  const IppoCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;

  /// Defaults to the theme's card colour.
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: color ?? tokens.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: tokens.surfaceStyle == SurfaceStyle.outlined
            ? BorderSide(color: tokens.cardBorder, width: 1.5)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// The card holding a screen's one primary action.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.label,
    required this.title,
    this.figure,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  /// A short heading above the content, for example "Today's step".
  final String label;

  /// A number shown large before [title], for example "12".
  final String? figure;
  final String title;
  final String? detail;

  /// The button; omitted when there is nothing to do.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final figure = this.figure;
    final detail = this.detail;
    final actionLabel = this.actionLabel;
    return IppoCard(
      color: tokens.heroBackground,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(color: tokens.heroMuted),
          ),
          Gaps.small,
          if (figure == null)
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: tokens.heroForeground,
              ),
            )
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              children: [
                Text(
                  figure,
                  textScaler: TextScaler.noScaling,
                  style: textTheme.displayLarge?.copyWith(
                    color: tokens.heroForeground,
                    fontSize: 80,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.heroForeground,
                    ),
                  ),
                ),
              ],
            ),
          if (detail != null) ...[
            Gaps.small,
            Text(
              detail,
              style: textTheme.bodyLarge?.copyWith(color: tokens.heroMuted),
            ),
          ],
          if (actionLabel != null) ...[
            Gaps.medium,
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.heroAction,
                foregroundColor: tokens.onHeroAction,
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
