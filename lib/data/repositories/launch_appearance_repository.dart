import 'package:ippo/domain/models/appearance_mode.dart';

/// Whether the screen shown while the app starts is light or dark.
enum LaunchBrightness {
  light,
  dark,

  /// Whatever the phone is in.
  system;

  /// The launch screen that goes with [mode]. Paper is a light theme;
  /// the system offers no third choice.
  static LaunchBrightness forMode(AppearanceMode mode) {
    return switch (mode) {
      AppearanceMode.automatic => LaunchBrightness.system,
      AppearanceMode.daylight || AppearanceMode.paper => LaunchBrightness.light,
      AppearanceMode.night => LaunchBrightness.dark,
    };
  }
}

/// Tells the system how the launch screen should look.
///
/// The system draws that screen before the app runs, so the app can only
/// say in advance what it will want next time.
abstract interface class LaunchAppearanceRepository {
  /// Remembers [brightness] for the next launches. Never throws: the
  /// launch screen is a nicety and must not get in the app's way.
  Future<void> setLaunchBrightness(LaunchBrightness brightness);
}
