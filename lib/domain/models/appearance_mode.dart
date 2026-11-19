/// How the learner wants the app to look.
enum AppearanceMode {
  /// Daylight while the device is in light mode, Night in dark mode.
  automatic,
  daylight,
  night,
  paper;

  /// The mode stored as [name]. A missing or unrecognised value is
  /// [automatic], so data from another version of the app never fails.
  static AppearanceMode fromName(String? name) {
    for (final mode in values) {
      if (mode.name == name) return mode;
    }
    return automatic;
  }
}
