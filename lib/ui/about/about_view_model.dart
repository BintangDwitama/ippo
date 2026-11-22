import 'package:flutter/foundation.dart';
import 'package:ippo/app_dependencies.dart';
import 'package:ippo/ui/core/view_model.dart';

@immutable
class AboutUiState {
  const AboutUiState({this.dictionaryDate, this.wordCount = 0});

  /// The date of the dictionary the bundled word list was built from, as
  /// `YYYY-MM-DD`; null if the app has no word list.
  final String? dictionaryDate;

  /// Words in the bundled list.
  final int wordCount;
}

class AboutViewModel extends ViewModel {
  AboutViewModel(AppDependencies deps)
      : uiState = AboutUiState(
          dictionaryDate: deps.wordListInfo?.dictionaryDate,
          wordCount: deps.wordListInfo?.keys.length ?? 0,
        );

  final AboutUiState uiState;
}
