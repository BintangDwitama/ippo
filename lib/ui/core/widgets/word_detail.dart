import 'package:flutter/material.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/widgets/audio_button.dart';
import 'package:ippo/ui/core/widgets/word_text.dart';

/// A word in full: reading, written form, type, meanings and its sound.
class WordDetail extends StatelessWidget {
  const WordDetail({
    super.key,
    required this.word,
    required this.onPlay,
    required this.voiceAvailable,
  });

  final WordPayload word;
  final VoidCallback onPlay;
  final bool voiceAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        WordText(word, size: 72),
        Gaps.medium,
        Text(
          word.meaningText,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        Gaps.small,
        Text(
          word.partOfSpeech,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Gaps.medium,
        if (voiceAvailable)
          AudioButton(onPressed: onPlay)
        else
          Text(
            'No Japanese voice is installed on this phone, '
            'so the word cannot be played.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
