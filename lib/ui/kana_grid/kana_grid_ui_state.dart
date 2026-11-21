import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';

@immutable
class KanaCell {
  const KanaCell({required this.item, required this.status});

  final Item item;
  final KanaStatus status;
}

/// The kana of one group, laid out as a table.
@immutable
class KanaSection {
  const KanaSection({required this.group, required this.rows});

  final KanaGroup group;

  /// One row per consonant line. Each row has
  /// [KanaGridUiState.columns] entries; null marks a gap.
  final List<List<KanaCell?>> rows;
}

@immutable
class KanaGridUiState {
  const KanaGridUiState({
    this.isLoading = true,
    this.script = KanaScript.hiragana,
    this.sections = const [],
    this.knownCount = 0,
    this.learningCount = 0,
    this.totalCount = 0,
  });

  /// Number of columns in the gojūon table: a, i, u, e, o.
  static const int columns = 5;

  final bool isLoading;
  final KanaScript script;

  /// The selected script's kana by group: basic, voiced, combination.
  /// Groups without kana are left out.
  final List<KanaSection> sections;

  final int knownCount;
  final int learningCount;
  final int totalCount;
}
