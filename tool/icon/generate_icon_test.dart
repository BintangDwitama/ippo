// Writes the app icon's images. Run from the repository root:
//
//   flutter test tool/icon/generate_icon_test.dart
//
// It is a test file only because `flutter test` is the simplest way to
// use Flutter's text and image engine without a device. It is not part
// of the normal test run. What it draws is set in icon_renderer.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'icon_renderer.dart';

void main() {
  testWidgets('generate the app icon', (tester) async {
    await tester.runAsync(() async {
      final renderer = await IconRenderer.load();

      for (final density in IconSpec.densities.keys) {
        final foreground = File(IconSpec.foregroundPath(density));
        foreground.parent.createSync(recursive: true);
        foreground.writeAsBytesSync(
          await IconRenderer.png(await renderer.foreground(density)),
        );
        File(IconSpec.legacyPath(density)).writeAsBytesSync(
          await IconRenderer.png(await renderer.legacy(density)),
        );
      }

      // For looking at; the build folder is not committed.
      final previews = Directory('build/icon_preview')
        ..createSync(recursive: true);
      for (final (name, size, circle) in [
        ('circle_432', 432, true),
        ('rounded_432', 432, false),
        ('circle_96', 96, true),
        ('circle_48', 48, true),
      ]) {
        File('${previews.path}/$name.png').writeAsBytesSync(
          await IconRenderer.png(
            await renderer.preview(size, circle: circle),
          ),
        );
      }
      // ignore: avoid_print
      print('Icon images written. Previews are in ${previews.path}.');
    });
  });
}
