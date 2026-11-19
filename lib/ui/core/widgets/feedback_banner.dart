import 'package:flutter/material.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// Tells the learner whether an answer was right, with an icon and words
/// as well as colour.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.isCorrect,
    required this.label,
    this.detail,
  });

  final bool isCorrect;

  /// The verdict in a word or two, for example "Not quite".
  final String label;

  /// What was answered and what the answer is.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final background = isCorrect ? tokens.correct : tokens.wrong;
    final foreground = isCorrect ? tokens.onCorrect : tokens.onWrong;
    final detail = this.detail;

    final banner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.smallRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: foreground,
            size: 28,
          ),
          Gaps.small,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(color: foreground),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: textTheme.bodyLarge?.copyWith(color: foreground),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return banner;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      ),
      child: banner,
    );
  }
}
