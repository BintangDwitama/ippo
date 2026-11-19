import 'package:flutter/material.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// A mnemonic shown as a highlighted note.
class MnemonicNote extends StatelessWidget {
  const MnemonicNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.noteBackground,
        borderRadius: BorderRadius.circular(tokens.smallRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: tokens.noteForeground),
          Gaps.small,
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: tokens.noteForeground),
            ),
          ),
        ],
      ),
    );
  }
}
