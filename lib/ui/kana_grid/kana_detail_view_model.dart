import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/mnemonic.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/kana_grid/kana_detail_ui_state.dart';

class KanaDetailViewModel extends ViewModel {
  KanaDetailViewModel(this._deps, {required this.itemId}) {
    _subscriptions = [
      _deps.itemRepository.getItemsStream().listen((items) {
        _item = items.where((item) => item.id == itemId).firstOrNull;
        _recompute();
      }),
      _deps.cardRepository.getCardsStream().listen((cards) {
        _cards = cards.where((card) => card.itemId == itemId).toList();
        _recompute();
      }),
      _deps.mnemonicRepository.getMnemonicStream(itemId).listen((mnemonic) {
        _mnemonic = mnemonic;
        _recompute();
      }),
    ];
  }

  final AppDependencies _deps;
  final int itemId;
  late final List<StreamSubscription<void>> _subscriptions;

  Item? _item;
  Mnemonic? _mnemonic;
  List<ReviewCard> _cards = const [];
  bool _isMnemonicInvalid = false;

  KanaDetailUiState _uiState = const KanaDetailUiState();
  KanaDetailUiState get uiState => _uiState;

  void playSound() {
    final item = _item;
    if (item != null) {
      unawaited(_deps.speechRepository.speak(item.kana.character));
    }
  }

  /// Saves the learner's own mnemonic. Returns false, and flags the
  /// state, if [text] is empty.
  Future<bool> saveMnemonic(String text) async {
    try {
      await _deps.mnemonicRepository.saveLearnerText(itemId, text);
      _isMnemonicInvalid = false;
      _recompute();
      return true;
    } on ArgumentError {
      _isMnemonicInvalid = true;
      _recompute();
      return false;
    }
  }

  Future<void> restoreDefaultMnemonic() async {
    await _deps.mnemonicRepository.restoreDefault(itemId);
    _isMnemonicInvalid = false;
    _recompute();
  }

  void _recompute() {
    final item = _item;
    _uiState = KanaDetailUiState(
      item: item,
      mnemonic: _mnemonic,
      status: item == null
          ? _uiState.status
          : _deps.getKanaStatus(item, _cards),
      isMnemonicInvalid: _isMnemonicInvalid,
    );
    notify();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_deps.speechRepository.stop());
    super.dispose();
  }
}
