import 'package:flutter/material.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';

/// A two-by-two grid of answer buttons.
class ChoiceGrid extends StatelessWidget {
  const ChoiceGrid({
    super.key,
    required this.labels,
    required this.onSelected,
    this.isKana = false,
  });

  final List<String> labels;
  final ValueChanged<int> onSelected;

  /// Whether the labels are kana characters and not romaji.
  final bool isKana;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = FilledButton.styleFrom(
      backgroundColor: tokens.choiceBackground,
      foregroundColor: tokens.choiceForeground,
      padding: const EdgeInsets.all(8),
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
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isKana ? 1.6 : 2.2,
          children: [
            for (var i = 0; i < labels.length; i++)
              FilledButton(
                style: style,
                onPressed: () => onSelected(i),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[i],
                    locale: isKana ? const Locale('ja') : null,
                    style: isKana
                        ? TextStyle(
                            fontFamily: tokens.kanaFontFamily,
                            fontSize: 44,
                          )
                        : const TextStyle(fontSize: 26),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
