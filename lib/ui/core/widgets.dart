import 'package:flutter/material.dart';
import 'package:ippo/ui/core/app_theme.dart';

/// A kana character drawn large, using Japanese glyph shapes.
class KanaText extends StatelessWidget {
  const KanaText(this.character, {super.key, this.size = 120});

  final String character;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      character,
      // The Japanese locale selects Japanese forms from the system CJK font.
      locale: const Locale('ja'),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        height: 1.1,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Plays the sound of the kana on screen.
class AudioButton extends StatelessWidget {
  const AudioButton({super.key, required this.onPressed, this.large = false});

  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      iconSize: large ? 56 : 28,
      padding: EdgeInsets.all(large ? 24 : 12),
      tooltip: 'Play sound',
      icon: const Icon(Icons.volume_up),
    );
  }
}

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
              FilledButton.tonal(
                onPressed: () => onSelected(i),
                child: Text(
                  labels[i],
                  locale: isKana ? const Locale('ja') : null,
                  style: TextStyle(fontSize: isKana ? 44 : 26),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A mnemonic shown as a highlighted note.
class MnemonicNote extends StatelessWidget {
  const MnemonicNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: scheme.onSecondaryContainer),
          Gaps.small,
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A centred message with an optional action, for empty and end states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            Gaps.medium,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            if (detail != null) ...[
              Gaps.small,
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (actionLabel != null) ...[
              Gaps.large,
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Describes how long until [time], for example "in 10 min".
String formatTimeUntil(DateTime time, DateTime now) {
  final wait = time.difference(now);
  if (wait.inMinutes < 1) return 'in less than a minute';
  if (wait.inMinutes < 60) return 'in ${wait.inMinutes} min';
  if (wait.inHours < 24) {
    return wait.inHours == 1 ? 'in 1 hour' : 'in ${wait.inHours} hours';
  }
  return wait.inDays == 1 ? 'in 1 day' : 'in ${wait.inDays} days';
}
