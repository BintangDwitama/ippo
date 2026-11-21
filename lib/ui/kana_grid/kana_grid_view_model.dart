import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/kana_grid/kana_grid_ui_state.dart';

class KanaGridViewModel extends ViewModel {
  KanaGridViewModel(this._deps) {
    _subscriptions = [
      _deps.itemRepository.getItemsStream().listen((items) {
        _items = items;
        _recompute();
      }),
      _deps.cardRepository.getCardsStream().listen((cards) {
        _cards = cards;
        _recompute();
      }),
    ];
  }

  static const _vowels = ['a', 'i', 'u', 'e', 'o'];

  final AppDependencies _deps;
  late final List<StreamSubscription<void>> _subscriptions;

  List<Item>? _items;
  List<ReviewCard>? _cards;
  KanaScript _script = KanaScript.hiragana;

  KanaGridUiState _uiState = const KanaGridUiState();
  KanaGridUiState get uiState => _uiState;

  void selectScript(KanaScript script) {
    _script = script;
    _recompute();
  }

  void _recompute() {
    final items = _items;
    final cards = _cards;
    if (items == null || cards == null) return;

    final cardsByItem = <int, List<ReviewCard>>{};
    for (final card in cards) {
      cardsByItem.putIfAbsent(card.itemId, () => []).add(card);
    }
    final cells = [
      for (final item in items)
        if (item.kind == ItemKind.kana && item.kana.script == _script)
          KanaCell(
            item: item,
            status: _deps.getKanaStatus(item, cardsByItem[item.id] ?? const []),
          ),
    ];

    _uiState = KanaGridUiState(
      isLoading: false,
      script: _script,
      sections: [
        for (final group in KanaGroup.values)
          if (cells.any((c) => c.item.kana.group == group))
            KanaSection(
              group: group,
              rows: _toRows(
                cells.where((c) => c.item.kana.group == group).toList(),
              ),
            ),
      ],
      knownCount: cells.where((c) => c.status == KanaStatus.known).length,
      learningCount:
          cells.where((c) => c.status == KanaStatus.learning).length,
      totalCount: cells.length,
    );
    notify();
  }

  /// Lays the cells out as a table: one row per consonant line, one
  /// column per vowel, with gaps where a sound does not exist.
  List<List<KanaCell?>> _toRows(List<KanaCell> cells) {
    final rows = <List<KanaCell?>>[];
    String? currentRow;
    var lastColumn = KanaGridUiState.columns;
    for (final cell in cells) {
      final kana = cell.item.kana;
      final column = _column(kana.romaji);
      // A kana starts a new table row when its consonant line changes.
      // Where the line is unknown, a vowel that does not advance does.
      final startsRow = kana.row.isEmpty
          ? column <= lastColumn
          : kana.row != currentRow;
      if (startsRow || rows.isEmpty) {
        rows.add(List<KanaCell?>.filled(KanaGridUiState.columns, null));
      }
      rows.last[column] = cell;
      lastColumn = column;
      currentRow = kana.row;
    }
    return rows;
  }

  int _column(String romaji) {
    final index = _vowels.indexOf(romaji.substring(romaji.length - 1));
    // "n" has no vowel; it sits alone in the first column.
    return index < 0 ? 0 : index;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
