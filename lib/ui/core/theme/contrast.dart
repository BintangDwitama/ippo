import 'dart:ui';

/// The WCAG 2 contrast ratio between two opaque colours, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// A text colour and the surface it is drawn on.
class ContrastPair {
  const ContrastPair(this.name, this.foreground, this.background);

  final String name;
  final Color foreground;
  final Color background;

  double get ratio => contrastRatio(foreground, background);
}
