import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/appearance_mode.dart';

/// State of the app as a whole, above any one screen.
@immutable
class AppUiState {
  const AppUiState({this.appearanceMode = AppearanceMode.automatic});

  final AppearanceMode appearanceMode;
}
