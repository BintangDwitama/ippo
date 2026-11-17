import 'package:drift/drift.dart';
import 'package:ippo/data/repositories/mnemonic_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/mnemonic.dart';

class DriftMnemonicRepository implements MnemonicRepository {
  DriftMnemonicRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$MnemonicsTable, MnemonicRow> _byItem(int itemId) =>
      _db.select(_db.mnemonics)..where((t) => t.itemId.equals(itemId));

  @override
  Stream<Mnemonic> getMnemonicStream(int itemId) {
    return _byItem(itemId).watchSingle().map(_toMnemonic);
  }

  @override
  Future<Mnemonic> getMnemonic(int itemId) async {
    return _toMnemonic(await _byItem(itemId).getSingle());
  }

  @override
  Future<void> saveLearnerText(int itemId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'A mnemonic cannot be empty');
    }
    await _write(itemId, trimmed);
  }

  @override
  Future<void> restoreDefault(int itemId) => _write(itemId, null);

  Future<void> _write(int itemId, String? learnerText) {
    return (_db.update(_db.mnemonics)..where((t) => t.itemId.equals(itemId)))
        .write(MnemonicsCompanion(learnerText: Value(learnerText)));
  }

  Mnemonic _toMnemonic(MnemonicRow row) {
    return Mnemonic(
      itemId: row.itemId,
      defaultText: row.defaultText,
      learnerText: row.learnerText,
    );
  }
}
