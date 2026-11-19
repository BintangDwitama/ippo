import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// The main action of a screen or card, full width.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

/// A less prominent action next to or below a primary one, full width.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return switch (context.tokens.surfaceStyle) {
      SurfaceStyle.filled => FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      ),
      SurfaceStyle.outlined => OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    };
  }
}
