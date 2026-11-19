import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// A horizontal bar showing how much of something is done, from 0 to 1.
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({super.key, required this.value, this.height = 10});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1).toDouble()),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, shown, _) => LinearProgressIndicator(
        value: shown,
        minHeight: height,
        borderRadius: BorderRadius.circular(height / 2),
        color: tokens.progressFill,
        backgroundColor: tokens.progressTrack,
      ),
    );
  }
}
