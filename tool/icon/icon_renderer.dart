// Draws the app icon from the bundled kana font. Used by the generator
// (tool/icon/generate_icon_test.dart) and by the test that checks the
// committed images still match.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// What the icon is made of. Change these and regenerate.
abstract final class IconSpec {
  /// The mark: "step", the second half of the app's name 一歩.
  static const String character = '歩';

  static const String fontAsset = 'assets/fonts/KleeOne-SemiBold.ttf';
  static const String fontFamily = 'IconKlee';

  /// The Daylight theme's blue.
  static const ui.Color background = ui.Color(0xFF2459E0);
  static const ui.Color mark = ui.Color(0xFFFFFFFF);

  /// An adaptive icon layer is 108 dp square; launchers show at least
  /// the central circle of 66 dp.
  static const double layerDp = 108;
  static const double safeCircleDp = 66;

  /// The longer side of the mark's ink on the adaptive layer. Its
  /// corners must stay inside the safe circle.
  static const double markDp = 46;

  /// Android's screen densities and their scale.
  static const Map<String, double> densities = {
    'mdpi': 1,
    'hdpi': 1.5,
    'xhdpi': 2,
    'xxhdpi': 3,
    'xxxhdpi': 4,
  };

  /// A launcher icon before adaptive icons is 48 dp.
  static const double legacyDp = 48;

  /// The share of the legacy icon's side the mark's ink takes.
  static const double legacyMarkShare = 0.62;

  /// The corner radius of the legacy icon, as a share of its side.
  static const double legacyRadiusShare = 0.22;

  static const String resDir = 'android/app/src/main/res';

  static String foregroundPath(String density) =>
      '$resDir/mipmap-$density/ic_launcher_foreground.png';

  static String legacyPath(String density) =>
      '$resDir/mipmap-$density/ic_launcher.png';
}

/// Renders the icon's images. Create with [IconRenderer.load].
class IconRenderer {
  IconRenderer._(this._inkBounds);

  /// The font size the mark is measured at.
  static const double _measureSize = 800;
  static const int _measureCanvas = 1600;

  /// Where the mark's ink lies when the character is laid out at
  /// [_measureSize] with its paragraph at the origin.
  final ui.Rect _inkBounds;

  /// Loads the font and measures the mark's ink. A glyph's box is rarely
  /// centred on what is actually drawn, so the ink itself is measured.
  static Future<IconRenderer> load() async {
    final loader = FontLoader(IconSpec.fontFamily)
      ..addFont(
        Future.value(
          ByteData.sublistView(File(IconSpec.fontAsset).readAsBytesSync()),
        ),
      );
    await loader.load();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const origin = ui.Offset(_measureCanvas / 4, _measureCanvas / 4);
    canvas.drawParagraph(_paragraph(_measureSize, IconSpec.mark), origin);
    final image = await recorder
        .endRecording()
        .toImage(_measureCanvas, _measureCanvas);
    final pixels = await rgba(image);

    var left = _measureCanvas, top = _measureCanvas, right = -1, bottom = -1;
    for (var y = 0; y < _measureCanvas; y++) {
      for (var x = 0; x < _measureCanvas; x++) {
        if (pixels[(y * _measureCanvas + x) * 4 + 3] > 8) {
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }
    if (right < 0) {
      throw StateError('The font drew nothing for ${IconSpec.character}');
    }
    return IconRenderer._(
      ui.Rect.fromLTRB(
        left - origin.dx,
        top - origin.dy,
        right + 1 - origin.dx,
        bottom + 1 - origin.dy,
      ),
    );
  }

  /// The adaptive icon's foreground at [density]: the mark alone, on a
  /// transparent layer. The system also uses it, by its shape only, as
  /// the one-colour layer for themed icons.
  Future<ui.Image> foreground(String density) {
    final scale = IconSpec.densities[density]!;
    final size = (IconSpec.layerDp * scale).round();
    return _draw(size, (canvas) {
      _drawMark(canvas, size.toDouble(), IconSpec.markDp * scale);
    });
  }

  /// The complete icon for Android versions without adaptive icons: the
  /// mark on a blue rounded square.
  Future<ui.Image> legacy(String density) {
    final scale = IconSpec.densities[density]!;
    final size = (IconSpec.legacyDp * scale).round();
    return _draw(size, (canvas) {
      final side = size.toDouble();
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(0, 0, side, side),
          ui.Radius.circular(side * IconSpec.legacyRadiusShare),
        ),
        ui.Paint()
          ..color = IconSpec.background
          ..isAntiAlias = true,
      );
      _drawMark(canvas, side, side * IconSpec.legacyMarkShare);
    });
  }

  /// The icon as a launcher shows it, for looking at: the foreground on
  /// its background, cut to a circle or a rounded square of [size].
  Future<ui.Image> preview(int size, {required bool circle}) {
    return _draw(size, (canvas) {
      final side = size.toDouble();
      final bounds = ui.Rect.fromLTWH(0, 0, side, side);
      canvas.clipRRect(
        ui.RRect.fromRectAndRadius(
          bounds,
          ui.Radius.circular(circle ? side / 2 : side * 0.28),
        ),
      );
      canvas.drawRect(bounds, ui.Paint()..color = IconSpec.background);
      // A launcher shows the central 72 dp of the 108 dp layer.
      final shown = side * IconSpec.layerDp / 72;
      canvas.translate((side - shown) / 2, (side - shown) / 2);
      _drawMark(canvas, shown, shown * IconSpec.markDp / IconSpec.layerDp);
    });
  }

  /// Draws the mark centred in a square of [side], its ink's longer side
  /// [extent] long.
  void _drawMark(ui.Canvas canvas, double side, double extent) {
    final k = extent / _inkBounds.longestSide;
    final centre = _inkBounds.center * k;
    canvas.drawParagraph(
      _paragraph(_measureSize * k, IconSpec.mark),
      ui.Offset(side / 2 - centre.dx, side / 2 - centre.dy),
    );
  }

  static ui.Paragraph _paragraph(double fontSize, ui.Color color) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: IconSpec.fontFamily,
        fontSize: fontSize,
        height: 1,
        locale: const ui.Locale('ja'),
      ),
    )
      ..pushStyle(ui.TextStyle(color: color))
      ..addText(IconSpec.character);
    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
  }

  static Future<ui.Image> _draw(
    int size,
    void Function(ui.Canvas canvas) paint,
  ) {
    final recorder = ui.PictureRecorder();
    paint(ui.Canvas(recorder));
    return recorder.endRecording().toImage(size, size);
  }

  /// The pixels of [image], four bytes each: red, green, blue, alpha.
  static Future<Uint8List> rgba(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }

  static Future<Uint8List> png(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Decodes a PNG file to its pixels.
  static Future<({int width, int height, Uint8List rgba})> readPng(
    String path,
  ) async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    return (width: image.width, height: image.height, rgba: await rgba(image));
  }
}
