import 'package:meta/meta.dart';

/// What the app knows about the word list it was built with.
@immutable
class WordListInfo {
  const WordListInfo({required this.dictionaryDate, required this.keys});

  /// The date of the dictionary the list was built from, as `YYYY-MM-DD`.
  final String dictionaryDate;

  /// The item keys of the words in the list. A word stored on the phone
  /// but missing here was dropped from the list by a later version.
  final Set<String> keys;
}
