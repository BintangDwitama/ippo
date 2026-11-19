import 'package:flutter/material.dart';

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
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: 'Play sound',
      icon: const Icon(Icons.volume_up),
    );
  }
}
