import 'package:flutter/foundation.dart';

/// The bundled font families and the licence file of each.
const Map<String, String> _fontLicenses = {
  'Klee One': 'assets/fonts/licenses/kleeone-OFL.txt',
  'Plus Jakarta Sans': 'assets/fonts/licenses/plusjakartasans-OFL.txt',
  'Space Grotesk': 'assets/fonts/licenses/spacegrotesk-OFL.txt',
  'Inter': 'assets/fonts/licenses/inter-OFL.txt',
  'Source Serif 4': 'assets/fonts/licenses/sourceserif4-OFL.txt',
};

/// Adds the bundled fonts to the app's licences page.
///
/// [loadText] reads an asset as text; the licences are only read when the
/// page is opened.
void registerFontLicenses(Future<String> Function(String asset) loadText) {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: asset) in _fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([family], await loadText(asset));
    }
  });
}
