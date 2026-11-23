import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/icon/icon_renderer.dart';

/// Checks the committed icon images. They are written by
/// `flutter test tool/icon/generate_icon_test.dart`.
void main() {
  const res = IconSpec.resDir;

  String rgbHex(int r, int g, int b) =>
      [r, g, b].map((v) => v.toRadixString(16).padLeft(2, '0')).join();

  testWidgets('the foreground is the mark alone, inside the safe circle', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: density, value: scale)
          in IconSpec.densities.entries) {
        final image =
            await IconRenderer.readPng(IconSpec.foregroundPath(density));
        final size = (IconSpec.layerDp * scale).round();
        expect(image.width, size, reason: density);
        expect(image.height, size, reason: density);

        // The corners are transparent; all ink lies within the circle
        // every launcher shows.
        final centre = size / 2;
        final safeRadius = IconSpec.safeCircleDp * scale / 2;
        var farthest = 0.0;
        var inked = 0;
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final i = (y * size + x) * 4;
            if (image.rgba[i + 3] < 16) continue;
            inked++;
            final d = sqrt(pow(x + 0.5 - centre, 2) + pow(y + 0.5 - centre, 2));
            if (d > farthest) farthest = d;
          }
        }
        expect(inked, greaterThan(size * size ~/ 50), reason: density);
        expect(farthest, lessThanOrEqualTo(safeRadius), reason: density);
        // And it is not timid: the mark reaches most of the way out.
        expect(farthest, greaterThan(safeRadius * 0.7), reason: density);
        expect(image.rgba[3], 0, reason: '$density corner');
      }
    });
  });

  testWidgets('the icon for older Android is the mark on the blue', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: density, value: scale)
          in IconSpec.densities.entries) {
        final image = await IconRenderer.readPng(IconSpec.legacyPath(density));
        final size = (IconSpec.legacyDp * scale).round();
        expect(image.width, size, reason: density);
        expect(image.height, size, reason: density);

        // Blue just inside the middle of the top edge, see-through at
        // the rounded corner, and white somewhere in the middle.
        final top = ((size ~/ 12) * size + size ~/ 2) * 4;
        expect(
          rgbHex(image.rgba[top], image.rgba[top + 1], image.rgba[top + 2]),
          '2459e0',
          reason: density,
        );
        expect(image.rgba[top + 3], 255, reason: density);
        expect(image.rgba[3], 0, reason: '$density corner');
        var white = 0;
        for (var i = 0; i < image.rgba.length; i += 4) {
          if (image.rgba[i] > 240 &&
              image.rgba[i + 1] > 240 &&
              image.rgba[i + 2] > 240 &&
              image.rgba[i + 3] == 255) {
            white++;
          }
        }
        expect(white, greaterThan(size * size ~/ 40), reason: density);
      }
    });
  });

  testWidgets('drawing the icon again gives the committed images', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final renderer = await IconRenderer.load();
      for (final density in IconSpec.densities.keys) {
        expect(
          await IconRenderer.rgba(await renderer.foreground(density)),
          (await IconRenderer.readPng(IconSpec.foregroundPath(density))).rgba,
          reason: 'foreground $density: run the generator and commit',
        );
        expect(
          await IconRenderer.rgba(await renderer.legacy(density)),
          (await IconRenderer.readPng(IconSpec.legacyPath(density))).rgba,
          reason: 'legacy $density: run the generator and commit',
        );
      }
    });
  });

  group('Android resources', () {
    String read(String path) => File('$res/$path').readAsStringSync();

    test('the adaptive icon names its three layers', () {
      final xml = read('mipmap-anydpi-v26/ic_launcher.xml');
      expect(xml, contains('<adaptive-icon'));
      expect(
        xml,
        contains('<background android:drawable="@color/ic_launcher_background"'),
      );
      expect(
        xml,
        contains('<foreground android:drawable="@mipmap/ic_launcher_foreground"'),
      );
      expect(
        xml,
        contains('<monochrome android:drawable="@mipmap/ic_launcher_foreground"'),
      );
    });

    test('the icon background is the colour the tool draws with', () {
      final argb = IconSpec.background.toARGB32();
      final hex = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
      expect(
        read('values/colors.xml').toLowerCase(),
        contains('<color name="ic_launcher_background">#$hex</color>'),
      );
    });

    test('the launch screen has a light and a dark colour', () {
      expect(read('values/colors.xml'), contains('name="launch_background"'));
      expect(
        read('values-night/colors.xml').toUpperCase(),
        contains('<COLOR NAME="LAUNCH_BACKGROUND">#0F1218</COLOR>'),
      );
    });

    test('Android 12 and later use it for their own launch screen', () {
      for (final folder in ['values-v31', 'values-night-v31']) {
        expect(
          read('$folder/styles.xml'),
          contains(
            '<item name="android:windowSplashScreenBackground">'
            '@color/launch_background</item>',
          ),
          reason: folder,
        );
      }
    });

    test('earlier versions show the mark on it, and nothing is white', () {
      for (final folder in ['drawable', 'drawable-v21']) {
        final xml = read('$folder/launch_background.xml');
        expect(xml, contains('@color/launch_background'), reason: folder);
        expect(xml, contains('@mipmap/ic_launcher_foreground'), reason: folder);
        expect(xml, isNot(contains('@android:color/white')), reason: folder);
      }
      for (final folder in ['values', 'values-night']) {
        final styles = read('$folder/styles.xml');
        expect(styles, contains('name="LaunchTheme"'), reason: folder);
        expect(styles, contains('name="NormalTheme"'), reason: folder);
      }
    });

    test('the manifest points at the icon and the launch theme', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(manifest, contains('android:theme="@style/LaunchTheme"'));
      // Without this the activity would restart when the app's night
      // mode is set.
      expect(manifest, contains('uiMode'));
    });
  });
}
