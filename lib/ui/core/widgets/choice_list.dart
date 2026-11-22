import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// Answer buttons stacked one above the other, for answers too long for
/// the two-by-two [ChoiceGrid]: meanings and whole words.
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.children,
    required this.onSelected,
  });

  /// What each button shows, in order.
  final List<Widget> children;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = FilledButton.styleFrom(
      backgroundColor: tokens.choiceBackground,
      foregroundColor: tokens.choiceForeground,
      minimumSize: const Size.fromHeight(56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          tokens.cardRadius < 24 ? tokens.cardRadius : 24,
        ),
        side: BorderSide(color: tokens.choiceBorder, width: 1.5),
      ),
    );
    // Capped in width so the buttons stay a sensible size on tablets.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              FilledButton(
                style: style,
                onPressed: () => onSelected(i),
                child: children[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A meaning as an answer: up to two lines, centred.
class MeaningChoice extends StatelessWidget {
  const MeaningChoice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, height: 1.2),
    );
  }
}
