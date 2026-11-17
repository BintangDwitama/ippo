import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';

@immutable
class KanaCell {
  const KanaCell({required this.item, required this.status});

  final Item item;
  final KanaStatus status;
}

@immutable
class KanaGridUiState {
  const KanaGridUiState({
    this.isLoading = true,
    this.script = KanaScript.hiragana,
    this.rows = const [],
    this.knownCount = 0,
    this.learningCount = 0,
    this.totalCount = 0,
  });

  /// Number of columns in the gojūon table: a, i, u, e, o.
  static const int columns = 5;

  final bool isLoading;
  final KanaScript script;

  /// The gojūon table. Each row has [columns] entries; null marks a gap.
  final List<List<KanaCell?>> rows;

  final int knownCount;
  final int learningCount;
  final int totalCount;
}
