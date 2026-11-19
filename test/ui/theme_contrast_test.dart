import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/ui/core/theme/contrast.dart';
import 'package:ippo/ui/core/theme/app_themes.dart';
import 'package:ippo/ui/core/theme/theme_contrast_pairs.dart';

void main() {
  test('contrastRatio follows the WCAG formula', () {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);

    expect(contrastRatio(black, white), closeTo(21, 0.01));
    expect(contrastRatio(white, black), closeTo(21, 0.01));
    expect(contrastRatio(white, white), closeTo(1, 0.01));
  });

  final themes = AppThemes.all;

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    test('$name keeps all text at 4.5:1 or better', () {
      for (final pair in textContrastPairs(theme)) {
        expect(
          pair.ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name: ${pair.name} is ${pair.ratio.toStringAsFixed(2)}:1',
        );
      }
    });
  }
}
