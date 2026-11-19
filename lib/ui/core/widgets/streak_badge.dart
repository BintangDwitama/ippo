import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// The learner's streak in days, drawn as the theme asks.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final color = tokens.streakForeground;
    final count = Text(
      '$days',
      style: textTheme.headlineMedium?.copyWith(color: color, height: 1),
    );
    final caption = Text(
      'day streak',
      style: textTheme.labelMedium?.copyWith(color: color),
    );

    final Widget badge = switch (tokens.streakStyle) {
      StreakStyle.pill => Container(
        width: 104,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.streakBackground,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, color: color, size: 24),
              count,
              caption,
            ],
          ),
        ),
      ),
      StreakStyle.seal => SizedBox(
        width: 104,
        child: Center(
          child: Transform.rotate(
            angle: -0.07,
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.streakBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [count, caption],
                ),
              ),
            ),
          ),
        ),
      ),
    };

    return Semantics(
      label: days == 1 ? '1 day streak' : '$days day streak',
      child: ExcludeSemantics(child: badge),
    );
  }
}
