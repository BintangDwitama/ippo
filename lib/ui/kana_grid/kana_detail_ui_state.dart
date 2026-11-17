import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/mnemonic.dart';

@immutable
class KanaDetailUiState {
  const KanaDetailUiState({
    this.item,
    this.mnemonic,
    this.status = KanaStatus.notStarted,
    this.isMnemonicInvalid = false,
  });

  /// Null while loading.
  final Item? item;
  final Mnemonic? mnemonic;
  final KanaStatus status;

  /// The last attempt to save a mnemonic was rejected as empty.
  final bool isMnemonicInvalid;

  bool get isLoading => item == null || mnemonic == null;
}
